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
require 'auth'

#helpers do
  #
  # Basic認証のためのヘルパー
  #                                                                                                                                                                             
#  def protected!(name)
#    unless authorized?(name)
#      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
#      throw(:halt, [401, "Not authorized.\n"])
#    end
#  end
#  
#  def authorized?(name)
#    file = datafile(name,".passwd") || datafile(name,".password")
#    return true unless File.exist?(file)
#    a = File.read(file).split
#    user = a.shift
#    pass = a.shift
#    return true if user.to_s == '' || pass.to_s == ''
#    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
#    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [user,pass]
#  end
#end

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
  #protected!(name)
  q = params[:splat].join('/')    # /a/b/c/search の q を"b/c"にする

  authorized_by_cookie = true
  if auth_page_exist?(name,ALL_AUTH) then
    if !cookie_authorized?(name,ALL_AUTH) then
      authorized_by_cookie = false
    end
  end
  if !password_authorized?(name) then
    if !authorized_by_cookie then
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized.\n"])
    end
  end

  search(name,q)
end

get "/__search/:name" do |name|
  # protected!(name)
  q = params[:q]

  authorized_by_cookie = true
  if auth_page_exist?(name,ALL_AUTH) then
    if !cookie_authorized?(name,ALL_AUTH) then
      authorized_by_cookie = false
    end
  end
  if !password_authorized?(name) then
    if !authorized_by_cookie then
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized.\n"])
    end
  end

  redirect q == '' ? "#{URLROOT}/#{name}" : "#{URLROOT}/#{name}/#{q}/search"
end

# データ書込み 

post '/__write' do
  postdata = params[:data].split(/\n/)
  name = postdata[0]
  check_auth(name)
  writedata(postdata)
end

post '/__write__' do # 無条件書き込み
  postdata = params[:data].split(/\n/)
  name = postdata[0]
  check_auth(name)
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

#
# 認証の考え方
#
# 読み書き認証だけ設定されている場合 
#   読出しはOK
#   書込みだけNG
#   HPなどの場合
# 読出し認証だけ設定されている場合???
#      読出しも書込みもNG
#   or 読出しも書込みもOK
#
#   読出し 書込み
#   O      O               通常
#   O      X       => O O  HP      書込み認証
#   X      X       => O O  秘密    秘密認証 - basic認証と同等
#   X      0               無い
#
#                 r_authorized rw_authorized
#  普通にアクセス true         true          UIPediaなど
#  書込み禁止     true         false         HPなど
#  読出し禁止     false        false         増井研など
#
#
# 認証のアルゴリズム
#
# auth_page_exist?()      認証ページが存在して空じゃない
# r_cookie_authorized?()  Cookieで認証されている
# r_authorized            読出し権限あり
# rw_cookie_authorized?() Cookieで認証されている
# rw_authorized
#
# * 認証ページが存在しない状態で認証ページ編集しはじめた人には読み書き/読み出しCookieを与える ★★
# * 読み書き権限のある人には読み書き認証ページをrandomizeしない
# * 読み出し権限のある人には読み出し認証ページをrandomizeしない
# * 認証ページがある状態で、権限のない人が読み出し認証ページにアクセスすると
#  randomizeされる。読み出しはできる。書き込みはできない。
# * 認証ページがある状態で、権限のない人が読み書き認証ページにアクセスすると
#  randomizeされる。読み出しはできる。書き込みはできない。
# * 認証ページがある状態で、読み出し権限のある人が読み書き認証ページにアクセスすると、上と同様
#

# 認証文字列取得
post '/__tellauth' do
  postdata = params[:data].split(/\n/)
  name = postdata[0]
  title = postdata[1]
  useranswer = postdata[2]
  correctanswer = ansstring(readdata(name,title))
  if useranswer == correctanswer then # 認証成功!
    # Cookie設定
    if title == ALL_AUTH then
      response.set_cookie(auth_cookie(name,ALL_AUTH), {:value => 'authorized', :path => '/' })
    elsif title == WRITE_AUTH then
      response.set_cookie(auth_cookie(name,WRITE_AUTH), {:value => 'authorized', :path => '/' })
    end
  end
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
  check_auth(name)
  attr(name)
end

#
# リスト表示
#

def check_auth(name)
  authorized_by_cookie = true
  if auth_page_exist?(name,ALL_AUTH) then
    if !cookie_authorized?(name,ALL_AUTH) then
      authorized_by_cookie = false
    end
  end
  if !password_authorized?(name) then
    if !authorized_by_cookie then
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized.\n"])
    end
  end
end

get "/:name" do |name|
  check_auth(name)
  search(name)
end

get "/:name/" do |name|
  check_auth(name)
  search(name)
end

get "/:name/__sort" do |name|
  check_auth(name)
  search(name,'',true)
end

get "/:name/__list" do |name|
  # protected!(name)
  check_auth(name)
  list(name)
end

get '/:name/*/__access' do
  name = params[:name]
  title = params[:splat].join('/')
  check_auth(name)
  access(name,title)
end

get '/:name/*/__modify' do
  name = params[:name]
  title = params[:splat].join('/')
  check_auth(name)
  modify(name,title)
end

get "/:name/__random" do |name|
  check_auth(name)
  t = titles(name)
  len = t.length
  ignore = len / 2 # 新しい方からignore個は選ばない
  title = t[ignore + rand(len-ignore)]
  page(name,title)
end

get "/:name/rss.xml" do |name|
  check_auth(name)
  rss(name)
end

#
# データテキスト取得
#
get '/:name/*/text' do
  name = params[:name]
#  protected!(name)
  title = params[:splat].join('/')
  data = readdata(name,title)

  #
  # 「.読み出し認証」のときはデータを並びかえる (2012/5/4)
  # この場所でやるべきか?
  #
  if auth_page_exist?(name,ALL_AUTH) then
    if !cookie_authorized?(name,ALL_AUTH) && title == ALL_AUTH then
      data = randomize(data)
    end
  elsif auth_page_exist?(name,WRITE_AUTH) then
    if !cookie_authorized?(name,WRITE_AUTH) && title == WRITE_AUTH then
      data = randomize(data)
    end
  end
  data
end

get '/:name/*/text/:version' do      # 古いバージョンを取得
  name = params[:name]
#  protected!(name)
  title = params[:splat].join('/')
  version = params[:version].to_i
  data = readdata(name,title,version)
  #
  # 「認証」のときはデータを並びかえる
  #
  if auth_page_exist?(name,ALL_AUTH) then
    if !cookie_authorized?(name,ALL_AUTH) && title == ALL_AUTH then
      data = randomize(data)
    end
  elsif auth_page_exist?(name,WRITE_AUTH) then
    if !cookie_authorized?(name,WRITE_AUTH) && title == WRITE_AUTH then
      data = randomize(data)
    end
  end
  data
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
  title = params[:splat].join('/')
  check_auth(name)

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
  title = params[:splat].join('/')
  check_auth(name)
  redirect "/#{name}/#{title}"
end

get '/:name/*/__edit' do
  name = params[:name]
  title = params[:splat].join('/')
  check_auth(name)
  edit(name,title)
end

get '/:name/*/__edit/:version' do       # 古いバージョンを編集
  name = params[:name]
  check_auth(name)
  title = params[:splat].join('/')
  version = params[:version].to_i
  edit(name,title,version)
end

#
# ページ表示
#

get '/:name/*' do
  name = params[:name]               # Wikiの名前   (e.g. masui)
#  protected!(name)
  title = params[:splat].join('/')   # ページの名前 (e.g. TODO)

  authorized_by_cookie = false
  write_authorized = true
  if auth_page_exist?(name,ALL_AUTH) then
    if title != ALL_AUTH then
      if !cookie_authorized?(name,ALL_AUTH) then
        # redirect "/401.html"
      else
        authorized_by_cookie = true
      end
    else
      if !cookie_authorized?(name,ALL_AUTH) then
        write_authorized = false
      end
    end
  else
    if title == ALL_AUTH then
      response.set_cookie(auth_cookie(name,ALL_AUTH), {:value => 'authorized', :path => '/' })
    end

    if auth_page_exist?(name,WRITE_AUTH) then
      #if title != WRITE_AUTH then
        if !cookie_authorized?(name,WRITE_AUTH) then
          write_authorized = false
        end
      #end
    else
      if title == WRITE_AUTH then
        response.set_cookie(auth_cookie(name,WRITE_AUTH), {:value => 'authorized', :path => '/' })
      end
    end
  end

  if !password_authorized?(name) then
    if title != ALL_AUTH then
      if !authorized_by_cookie then
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized.\n"])
      end
    else
      # write_authorized = false
    end
  end

  page(name,title,write_authorized)
end
