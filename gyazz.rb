# -*- coding: utf-8 -*-
# -*- ruby -*-

require 'rubygems'
require 'sinatra'

enable :sessions   # Cookieを使うのに要るらしい

$: << 'lib'
require 'config'
require 'search'
require 'writedata'
require 'readdata'
require 'edit'
require 'page'
require 'attr'
require 'history'
require 'lib/rss'
require 'access'
require 'modify'

helpers do
  #
  # Basic認証のためのヘルパー
  #                                                                                                                                                                             
  def protected!(name)
    unless authorized?(name)
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized.\n"])
    end
  end
  
  def authorized?(name)
    file = datafile(name,".passwd") || datafile(name,".password")
    return true unless File.exist?(file)
    a = File.read(file).split
    user = a.shift
    pass = a.shift
    return true if user.to_s == '' || pass.to_s == ''
#File.open("/tmp/user","w"){ |f|
#  f.puts user
#  f.puts pass
#  f.puts @auth
#}
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [user,pass]
  end
end

get '/' do
  redirect "#{URLROOT}/Gyazz/目次"
end

get '/programs/*' do
  ''
end

#
# API
#
# 外に見せないサービスは /__xxx という名前にする
#

get '/:name/*/history' do
  name = params[:name]
  title = params[:splat].join('/')
  history(name,title)
end

get '/:name/*/search' do          # /増井研/合宿/search 
  name = params[:name]
  protected!(name)
  q = params[:splat].join('/')    # /a/b/c/search の q を"b/c"にする
  search(name,q)
end

get "/__search/:name" do |name|
  protected!(name)
  q = params[:q]
  redirect q == '' ? "#{URLROOT}/#{name}" : "#{URLROOT}/#{name}/#{q}/search"
end

# データ書込み 

post '/__write' do
  postdata = params[:data].split(/\n/)
  name = postdata[0]
  protected!(name)
  writedata(postdata)
end

post '/__write__' do # 無条件書き込み
  postdata = params[:data].split(/\n/)
  name = postdata[0]
  protected!(name)
  __writedata(postdata)
end

#get '/__write__' do # 無条件書き込み
#  postdata = params[:data].split(/\n/)
#  __writedata(postdata)
#end

get '/__setattr/:name/:key/:val' do |name,key,val|
  attr = SDBM.open("#{topdir(name)}/attr",0644);
  attr[key] = val
  attr.close
end

# Gyazoへの転送!
#
#  /__gyazoupload/(Gyazo ID)/(Gyazo URL) というリクエストが来る
#  Gyazo IDは各GyazoアプリのユニークID
#
get %r{/__gyazoupload/([0-9a-f]+)/(.*)} do |gyazoid,url|
  # GyazoID(アプリのID)とurlの対応関係を保存しておく
  url =~ /([\da-f]{32})/
  id = $1
  idimage = SDBM.open("#{FILEROOT}/idimage",0644)
  idimage[gyazoid] = idimage[gyazoid].to_s.split(/,/).unshift(id)[0,5].join(',')

  # 画像URLとGyazoIDの対応も保存する
  imageid = SDBM.open("#{FILEROOT}/imageid",0644)
  imageid[id] = gyazoid

  # CookieをセットしてGyazo.comに飛ぶ
  # response.set_cookie("GyazoID", gyazoid)
  response.set_cookie('GyazoID', {:value => gyazoid, :path => '/' })

  redirect url
end

#
# 設定
#

get "/:name/.settings" do |name|
  protected!(name)
  attr(name)
end

#
# リスト表示
#

get "/:name" do |name|
  protected!(name)
  search(name)
end

get "/:name/" do |name|
  protected!(name)
  search(name)
end

get "/:name/__sort" do |name|
  protected!(name)
  search(name,'',true)
end

get "/:name/__list" do |name|
  protected!(name)
  list(name)
end

get '/:name/*/__access' do
  name = params[:name]
  protected!(name)
  title = params[:splat].join('/')
  access(name,title)
end

get '/:name/*/__modify' do
  name = params[:name]
  protected!(name)
  title = params[:splat].join('/')
  modify(name,title)
end

get "/:name/__random" do |name|
  protected!(name)
  t = titles(name)
  len = t.length
  ignore = len / 2 # 新しい方からignore個は選ばない
  title = t[ignore + rand(len-ignore)]
  page(name,title)
end

get "/:name/rss.xml" do |name|
  protected!(name)
  rss(name)
end

#
# データテキスト取得
#

get '/:name/*/text' do
  name = params[:name]
  protected!(name)
  title = params[:splat].join('/')
  readdata(name,title)
end

get '/:name/*/text/:version' do      # 古いバージョンを取得
  name = params[:name]
  protected!(name)
  title = params[:splat].join('/')
  version = params[:version].to_i
  readdata(name,title,version)
end

#get "/:name/__related" do |name|
#  protected!(name)
#
#  top = topdir(name)
#  unless File.exist?(top) then
#    Dir.mkdir(top)
#  end
#
#  pair = Pair.new("#{top}/pair")
#  titles = pair.keys
#  pair.close
#
#  @id2title = {}
#  titles.each { |title|
#    @id2title[md5(title)] = title
#  }
#
#  ids = Dir.open(top).find_all { |file|
#    file =~ /^[\da-f]{32}$/ && @id2title[file].to_s != ''
#  }
#
#  @modtime = {}
#  ids.each { |id|
#    @modtime[id] = File.mtime("#{top}/#{id}")
#  }
#
#  ids.sort { |a,b|
#    @modtime[b] <=> @modtime[a]
#  }
#
#  @hotids = ids.sort { |a,b|
#    @modtime[b] <=> @modtime[a]
#  }
#
#  # JSON作成
#  $KCODE = "u"
#  "[\n" +
#    @hotids.collect { |id|
#    title = @id2title[id]
#    "  [\"#{title.gsub(/"/,'\"')}\", 0],\n" +
#    related(name,title).collect { |keyword|
#      "  [\"#{keyword.gsub(/"/,'\"')}\", 1]"
#    }.join(",\n")
#  }.join(",\n") +
#  "\n]\n"
#end

get '/:name/*/related' do
  name = params[:name]
  protected!(name)
  title = params[:splat].join('/')

#  pagekeywords = []
#  filename = datafile(name,title,0)
#  if File.exist?(filename) then
#    pagekeywords = File.read(filename).keywords
#  end

  top = topdir(name)
  unless File.exist?(top) then
    Dir.mkdir(top)
  end

  pair = Pair.new("#{top}/pair")
  relatedkeywords = {}
  pair.each(title){ |keyword|
    relatedkeywords[keyword] = true
  }
  pair.close

  # JSON作成
  $KCODE = "u"
  "[\n" +
    relatedkeywords.keys.collect { |keyword|
    "  \"#{keyword.gsub(/"/,'\"')}\""
  }.join(",\n") +
    "\n]\n"
end

#
# 編集モード
#

get '/:name/*/edit' do
  name = params[:name]
  protected!(name)
  title = params[:splat].join('/')
  redirect "/#{name}/#{title}"
end

get '/:name/*/__edit' do
  name = params[:name]
  protected!(name)
  title = params[:splat].join('/')
  edit(name,title)
end

get '/:name/*/__edit/:version' do       # 古いバージョンを編集
  name = params[:name]
  protected!(name)
  title = params[:splat].join('/')
  version = params[:version].to_i
  edit(name,title,version)
end

#
# ページ表示
#

get '/:name/*' do
  name = params[:name]               # Wikiの名前   (e.g. masui)
  protected!(name)
  title = params[:splat].join('/')   # ページの名前 (e.g. TODO)
  page(name,title)
end


