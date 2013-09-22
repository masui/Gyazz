# -*- coding: utf-8 -*-
# -*- ruby -*-

require 'json'
require 'date'

enable :sessions   # Cookieを使うのに要るらしい

$:.unshift File.expand_path 'lib', File.dirname(__FILE__)
require 'lib'
require 'config'
require 'search'
require 'writedata'
require 'readdata'
require 'edit'
require 'page'
require 'attr'
require 'history'
require 'rss'
require 'access'
require 'modify'
require 'auth'
require 'contenttype'

# require 'tmpshare'

configure do
  set :protection, :except => :frame_options
end

get '/' do
  redirect "#{app_root}#{DEFAULTPAGE}"
end

# get '/programs/*' do
#   ''
# end

#
# API
#
# 外に見せないサービスは /__xxx という名前にする
#

get '/:name/*/history' do
  name = params[:name]
  title = params[:splat].join('/')
  history_json(name,title)
end

get '/:name/*/search' do          # /増井研/合宿/search 
  name = params[:name]
  #protected!(name)
  q = params[:splat].join('/')    # /a/b/c/search の q を"b/c"にする
  check_auth(name)
  search(name,q)
end

get "/__search/:name" do |name|
  # protected!(name)
  q = params[:q]
  check_auth(name)
  redirect q == '' ? "#{app_root}/#{name}/" : "#{app_root}/#{name}/#{q}/search"
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

get '/__write__' do # 無条件書き込み
  postdata = params[:data].split(/\n/)
  name = postdata[0]
  check_auth(name)
  __writedata(postdata)
end

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
#get %r{/__gyazoupload/([0-9a-f]+)/(.*)} do |gyazoid,url|
#  # GyazoID(アプリのID)とurlの対応関係を保存しておく
#  url =~ /([\da-f]{32})/
#  id = $1
#  idimage = SDBM.open("#{FILEROOT}/idimage",0644)
#  idimage[gyazoid] = idimage[gyazoid].to_s.split(/,/).unshift(id)[0,5].join(',')
#
#  # 画像URLとGyazoIDの対応も保存する
#  imageid = SDBM.open("#{FILEROOT}/imageid",0644)
#  imageid[id] = gyazoid
#
#  # CookieをセットしてGyazo.comに飛ぶ
#  # response.set_cookie("GyazoID", gyazoid)
#  response.set_cookie('GyazoID', {:value => gyazoid, :path => '/' })
#
#  redirect url
#end

post '/__upload' do
  param = params[:uploadfile]
  if param
    # アップロードされたファイルはTempfileクラスになる
    tempfile = param[:tempfile]
    file_contents = tempfile.read
    file_ext = File.extname(param[:filename]).to_s
    tempfile.close # 消してしまう

    UPLOADDIR = "#{FILEROOT}/upload"
    Dir.mkdir(UPLOADDIR) unless File.exist?(UPLOADDIR)

    hash = md5(file_contents)
    savefile = "#{hash}#{file_ext}"
    savepath = "#{UPLOADDIR}/#{savefile}"
    File.open(savepath, 'wb'){ |f| f.write(file_contents) }

    savefile
  end
end

get "/upload/:filename" do |filename|
  UPLOADDIR = "#{FILEROOT}/upload"
  content_type contenttype(File.extname(filename))
  File.read("#{UPLOADDIR}/#{filename}")
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
  authorized_by_cookie = false
  if auth_page_exist?(name,ALL_AUTH) then
    if cookie_authorized?(name,ALL_AUTH) then
      authorized_by_cookie = true
    end
  end
  # 前はこうなっていた。変だと思うが何故放置されてたのか...? (2013/03/16 11:40:44)
  #authorized_by_cookie = true
  #if auth_page_exist?(name,ALL_AUTH) then
  #  if !cookie_authorized?(name,ALL_AUTH) then
  #    authorized_by_cookie = false
  #  end
  #end

  if !password_authorized?(name) then
    if !authorized_by_cookie then
      response['WWW-Authenticate'] = %(Basic realm="#{name}")
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

get '/:name/*/access.png' do
  name = params[:name]
  title = params[:splat].join('/')
  # history(name,title)
  # send_file "#{backupdir(name,title)}/access.png"
  history_png(name,title)
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
  ignore = 0
  title = t[ignore + rand(len-ignore)]
  page(name,title)
end

get "/:name/rss.xml" do |name|
  # check_auth(name)
  rss(name)
end

#
# JSON 
#
get '/:name/*/json' do
  name = params[:name]
  title = params[:splat].join('/')
  data = readdata(name,title)
  response["Access-Control-Allow-Origin"] = "*"
  data.split(/\n/).to_json
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
  else
    check_auth(name)
  end
  # response["Access-Control-Allow-Origin"] = "*"
  data
end


## ページの代表画像があればリダイレクトする
get '/:name/*/icon' do
  name = params[:name]
  title = params[:splat].join('/')
  repimage = SDBM.open("#{topdir(name)}/repimage")
  img = repimage[title]
  halt 404, "image not found" if img.to_s.empty?
  redirect case img
           when /^https?:\/\/.+\.(png|jpe?g|gif)$/i
             img
           else
             "http://gyazo.com/#{img}.png"
           end
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
  # 新規ページ作成時、大文字小文字を間違えたページが既に作られていないかチェック
  if !data or data.strip.empty? or data.strip == "(empty)"
    similar_titles = similar_page_titles(name, title)
    unless similar_titles.empty?
      suggest_title = similar_titles.sort{|a,b|
        readdata(name, b).size <=> readdata(name, a).size  # 一番大きいページをサジェスト
      }.first
      data = "\n-> [[#{suggest_title}]]" if suggest_title
    end
  end
  data
end

#
# GETでデータ書込みできるようにしてみる
#
#get '/:name/*/__write__/:data' do
#  name = params[:name]
##  protected!(name)
#  title = params[:splat].join('/')
#  data = params[:data]
#  File.open("/tmp/log","w"){ |f|
#    f.puts name
#    f.puts title
#    f.puts data
#  }
#end

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
    "  \"#{keyword.gsub(/\"/,'\"')}\""
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
  # protected!(name)
  title = params[:splat].join('/')   # ページの名前 (e.g. TODO)
#  request.fullpath =~ %r{/([^\/]+)/(.+)$}
#  name = $1
#  title = $2

#get %r{/([^\/]+)/([\w\?]+)$} do
#  name = params[:captures][0]
#  title = params[:captures][1]

#  File.open("/tmp/captures","w"){ |f|
#    f.puts params[:captures][2]
#  }

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
      rawdata = File.read(datafile(name,WRITE_AUTH))
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
        response['WWW-Authenticate'] = %(Basic realm="#{name}")
        throw(:halt, [401, "Not authorized.\n"])
      end
    else
      # write_authorized = false
    end
  end

  page(name,title,write_authorized)
end
