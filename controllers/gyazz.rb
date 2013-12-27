# -*- coding: utf-8 -*-
# -*- ruby -*-
#
# 外に見せないサービスは /__xxx という名前にする
# APIを綺麗にする #66
#

require 'json'
require 'date'

# Cookieを使う
enable :sessions
set :session_secret, SESSION_SECRET # 塩

configure do
  set :protection, :except => :frame_options
end

before '/:name/*' do
  # 認証に使う予定
  puts "BEFORE #{params[:name]} #{params[:splat]}"
end

get '/' do
  redirect "#{app_root}#{DEFAULTPAGE}"
end

#-----------------------------------------------------
# リスト表示 / 検索
#-----------------------------------------------------

get "/__search/:name" do |name|
  q = params[:q]
  if q == '' then
    redirect "#{app_root}/#{name}/"
  else
    search(name,q)
    erb :search
  end
end

#-----------------------------------------------------
# データ書込み
#-----------------------------------------------------

# データ書込み
post '/__write' do
  name = params[:name]
  title = params[:title]
  orig_md5 = params[:orig_md5]
  postdata = params[:data]

  page = Gyazz::Page.new(name,title)
  page.write(postdata,orig_md5)
end

get '/__write__' do # 無条件書き込み (gyazz-rubyで利用)
  data = params[:data].split(/\n/)
  if params[:name] then
    name = params[:name]
    title = params[:title]
  else
    name = data.shift
    title = data.shift
  end
  page = Gyazz::Page.new(name,title)
  page.write(data)
  #writedata(name,title,data)
  redirect("/#{name}/#{title}")
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
  correctanswer = ansstring(Gyazz::Page.new(name,title).text)
  if useranswer == correctanswer then # 認証成功!
    # Cookie設定
    if title == ALL_AUTH then
      response.set_cookie(auth_cookie(name,ALL_AUTH), {:value => 'authorized', :path => '/' })
    elsif title == WRITE_AUTH then
      response.set_cookie(auth_cookie(name,WRITE_AUTH), {:value => 'authorized', :path => '/' })
    end
  end
end

#-----------------------------------------------------
# ファイルアップロード関連
#-----------------------------------------------------

# ファイルをアップロード
post '/__upload' do
  param = params[:uploadfile]
  if param
    # アップロードされたファイルはTempfileクラスになる
    tempfile = param[:tempfile]
    file_contents = tempfile.read
    file_ext = File.extname(param[:filename]).to_s
    tempfile.close # 消してしまう

    hash = Gyazz.md5(file_contents)
    savefile = "#{hash}#{file_ext}"
    savepath = "#{Gyazz.uploaddir}/#{savefile}"
    File.open(savepath, 'wb'){ |f| f.write(file_contents) }

    savefile
  end
end

# アップロードされたファイルにアクセス
get "/upload/:filename" do |filename|
  send_file "#{FILEROOT}/upload/#{filename}"
end

#-----------------------------------------------------
# サイト属性関連
#-----------------------------------------------------

# サイト属性設定ページ
get "/:name/.settings" do |name|
  @wiki = Gyazz::Wiki.new(name)
  #@sortbydate = (wiki.attr['sortbydate'] == 'true')
  #@searchable = (wiki.attr['searchable'] == 'true')
  #@name = name
  erb :settings

  #@sortbydate = (attr(name,'sortbydate') == 'true')
  #@searchable = (attr(name,'searchable') == 'true')
  #@name = name
  #erb :settings
end

# サイト属性設定API (settings.erbから呼ばれる)
get '/__setattr/:name/:key/:val' do |name,key,val|
  wiki = Gyazz::Wiki.new(name)
  wiki.attr[key] = val
  # attr(name,key,val)
end

#-----------------------------------------------------
# ページリスト関連
#-----------------------------------------------------

# ページリスト表示
get "/:name" do |name|
  search(name)
  erb :search
end

get "/:name/" do |name|
  search(name)
  erb :search
end

# 名前でソートされたページリスト表示
# どこで使ってるのか??
# 日付ソートする場合もあるのに仕様がヘンでは?
get "/:name/__sort" do |name|
  search(name,'',true)
  erb :search
end

# gyazz-ruby gem のためのもの
get "/:name/__list" do |name|
  list(name)
end

#-----------------------------------------------------
# ページアクセス履歴/変更履歴関連
#-----------------------------------------------------

# ページ変更視覚化
get '/:name/*/modify.png' do
  name = params[:name]
  title = params[:splat].join('/')
  content_type 'image/png'
  page = Gyazz::Page.new(name,title)
  page.modify_png
end

# アクセス履歴
get '/:name/*/__access' do
  name = params[:name]
  title = params[:splat].join('/')
  Gyazz::Page.new(name,title).access_history.to_json
end

# 変更履歴
get '/:name/*/__modify' do
  name = params[:name]
  title = params[:splat].join('/')
  Gyazz::Page.new(name,title).modify_history.to_json
end

#-----------------------------------------------------
# RSS
#-----------------------------------------------------

get "/:name/rss.xml" do |name|
  rss(name,app_root)
end

#-----------------------------------------------------
# アイコンデータ
#-----------------------------------------------------

## ページの代表画像があればリダイレクトする
get '/:name/*/icon' do
  name = params[:name]
  title = params[:splat].join('/')
  image = repimage(name,title)
  halt 404, "image not found" if image.to_s.empty?
  redirect case image
           when /^https?:\/\/.+\.(png|jpe?g|gif)$/i
             image
           else
             "http://gyazo.com/#{image}.png"
           end
end

#-----------------------------------------------------
# ページデータ取得
#-----------------------------------------------------

# ページをJSONデータとして取得
get '/:name/*/json' do
  name = params[:name]
  title = params[:splat].join('/')
  redirect "/#{name}/#{title}/json/0"
end

# 古いバージョンのJSONを取得
get '/:name/*/json/:version' do
  name = params[:name]
  title = params[:splat].join('/')
  version = params[:version].to_i
  response["Access-Control-Allow-Origin"] = "*" # Ajaxを許可するオマジナイ
  data = Gyazz::Page.new(name,title).data(version)
  #
  # 認証ページのときは順番を入れ換える操作必要

  #
  # 新規ページ作成時、大文字小文字を間違えたページが既に作られていないかチェック ... ここでやるべきか?
  # 候補ページを追加してJSONで返すといいのかも?
  #
  # こんな感じのコードを入れる
  #  if !data or data.strip.empty? or data.strip == "(empty)"
  #    similar_titles = similar_page_titles(name, title)
  #    unless similar_titles.empty?
  #      suggest_title = similar_titles.sort{|a,b|
  #        readdata(name, b)['data'].join("\n").size <=> readdata(name, a)['data'].join("\n").size  # 一番大きいページをサジェスト
  #      }.first
  #      data = "\n-> [[#{suggest_title}]]" if suggest_title
  #    end
  #  end

  data.to_json
end

# ページをテキストデータとして取得
get '/:name/*/text' do
  name = params[:name]
  title = params[:splat].join('/')
  text = Gyazz::Page.new(name,title).text

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
  end
  # response["Access-Control-Allow-Origin"] = "*" Ajaxを許可するオマジナイ... 要るのか?
  text
end

#-----------------------------------------------------
# 関連ページ名取得
#-----------------------------------------------------

get '/:name/*/related' do
  name = params[:name]
  title = params[:splat].join('/')

  # 2ホップ先まで取得してしまうのだが
  Gyazz::Page.new(name,title).related_pages.collect { |page|
    page.title
  }.to_json

#  top = Gyazz.topdir(name)
#
#  pair = Pair.new("#{top}/pair")
#  related = pair.collect(title)
#  pair.close
#
#  related.to_json
end

#-----------------------------------------------------
# 編集モード
#-----------------------------------------------------

get '/:name/*/__edit' do
  name = params[:name]
  title = params[:splat].join('/')
  redirect "#{name}/#{title}/__edit/0"
end

get '/:name/*/__edit/:version' do       # 古いバージョンを編集
  name = params[:name]
  title = params[:splat].join('/')
  version = params[:version].to_i
  edit(name,title,version)
  erb :edit
end

#-----------------------------------------------------
# ページ表示関連
#-----------------------------------------------------

# ランダムにページを表示
get "/:name/__random" do |name|
  t = hottitles(name)
  len = t.length
  ignore = len / 2 # 新しい方からignore個は選ばない
  ignore = 0
  title = t[ignore + rand(len-ignore)]

  # ここも認証とかランダム化とか必要

  page = Gyazz::Page.new(name,title)

  @page = page
  erb :page2
end

# ページ表示
get '/:name/*' do
  name = params[:name]               # Wikiの名前   (e.g. masui)
  title = params[:splat].join('/')   # ページの名前 (e.g. TODO)

  page = Gyazz::Page.new(name,title)
  # page.access_count = page.access_count+1
  page.access

  @page = page
  erb :page2
end


# ページ表示
#get '/xxxxxx/:name/*' do
#  name = params[:name]               # Wikiの名前   (e.g. masui)
#  title = params[:splat].join('/')   # ページの名前 (e.g. TODO)
#
#
#  # アクセスカウンタインクリメント
#  access_count(name,title,access_count(name,title)+1)
#
#  # アクセス履歴を保存
#  access_history(name,title,true)
#
#  authorized_by_cookie = false
#  write_authorized = true
#  if auth_page_exist?(name,ALL_AUTH) then
#    if title != ALL_AUTH then
#      if !cookie_authorized?(name,ALL_AUTH) then
#        # redirect "/401.html"
#      else
#        authorized_by_cookie = true
#      end
#    else
#      if !cookie_authorized?(name,ALL_AUTH) then
#        write_authorized = false
#      end
#    end
#  else
#    if title == ALL_AUTH then
#      response.set_cookie(auth_cookie(name,ALL_AUTH), {:value => 'authorized', :path => '/' })
#    end
#
#    if auth_page_exist?(name,WRITE_AUTH) then
#      rawdata = File.read(Gyazz.datafile(name,WRITE_AUTH))
#      #if title != WRITE_AUTH then
#        if !cookie_authorized?(name,WRITE_AUTH) then
#          write_authorized = false
#        end
#      #end
#    else
#      if title == WRITE_AUTH then
#        response.set_cookie(auth_cookie(name,WRITE_AUTH), {:value => 'authorized', :path => '/' })
#      end
#    end
#  end
#
#  if !password_authorized?(name) then
#    if title != ALL_AUTH then
#      if !authorized_by_cookie then
#        response['WWW-Authenticate'] = %(Basic realm="#{name}")
#        throw(:halt, [401, "Not authorized.\n"])
#      end
#    else
#      # write_authorized = false
#    end
#  end
#
#  @page = page(name,title,write_authorized)
#  erb :page
#
#  #puts "Gyazz.rb: name=#{name}"
#  #@page = Page.new(name,title)
#  #erb :page
#
#end
