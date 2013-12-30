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
  name = params[:name]
  puts "BEFORE #{params[:name]} #{params[:splat]}"
  title = params[:splat][0]

  pass if title.index(Gyazz::ALL_AUTH) == 0
  pass if title.index(Gyazz::WRITE_AUTH) == 0
  #
  # パスワード認証に成功してるか、なぞなぞ認証に成功してればOK
  #
  wiki = Gyazz::Wiki.new(name)
  if !wiki.password_authorized?(request) then
    if !Gyazz::Page.new(wiki,Gyazz::ALL_AUTH).cookie_authorized?(request) &&
        !Gyazz::Page.new(wiki,Gyazz::WRITE_AUTH).cookie_authorized?(request) then
      response['WWW-Authenticate'] = %(Basic realm="#{name}")
      throw(:halt, [401, "Not authorized.\n"])
    end
  end
end

get '/' do
  redirect "#{DEFAULTPAGE}"
end

#-----------------------------------------------------
# リスト表示 / 検索
#-----------------------------------------------------

get "/__search/:name" do |name|
  q = params[:q]
  if q == '' then
    redirect "/#{name}/"
  else
    @wiki = Gyazz::Wiki.new(name)
    @pages = @wiki.pages(q)
    @q = q
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
  Gyazz::Page.new(name,title).write(postdata,orig_md5)
end

get '/__write__' do # 無条件書き込み (gyazz-rubyで利用)
  data = params[:data].split(/\n/)
  if params[:name] then
    name = params[:name]
    title = params[:title]
  else # この仕様は削除すべき
    name = data.shift
    title = data.shift
  end
  Gyazz::Page.new(name,title).write(data)
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

# なぞなぞ認証チャレンジ文字列取得
post '/__tellauth' do
  name = params[:name]
  title = params[:title]
  useranswer = params[:authstr]
  page = Gyazz::Page.new(name,title)
  if page.auth_page? then
    if useranswer == page.authanswer then # 認証成功!
      response.set_cookie(page.auth_cookie, {:value => 'authorized', :path => '/' })
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

    hash = file_contents.md5
    savefile = "#{hash}#{file_ext}"
    savepath = "#{FILEROOT}/upload/#{savefile}"
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
  erb :settings
end

# サイト属性設定API (settings.erbから呼ばれる)
get '/__setattr/:name/:key/:val' do |name,key,val|
  wiki = Gyazz::Wiki.new(name)
  wiki[key] = val
end

#-----------------------------------------------------
# ページリスト関連
#-----------------------------------------------------

# ページリスト表示
get "/:name" do |name|
  @wiki = Gyazz::Wiki.new(name)
  @pages = @wiki.pages
  erb :search
end

get "/:name/" do |name|
  @wiki = Gyazz::Wiki.new(name)
  @pages = @wiki.pages
  erb :search
end

# 名前でソートされたページリスト表示
# どこで使ってるのか??
# 日付ソートする場合もあるのに仕様がヘンでは?
get "/:name/__sort" do |name|
  @wiki = Gyazz::Wiki.new(name)
  @pages = @wiki.pages('',:title)
  erb :search
end

# gyazz-ruby gem のためのもの??
get "/:name/__list" do |name|
  Gyazz::Wiki.new(name).pages.collect { |page|
    [page.title, page.modtime.to_i, "#{name}/#{page.title}", page['repimage']]
  }.to_json
end

#-----------------------------------------------------
# ページアクセス履歴/変更履歴関連
#-----------------------------------------------------

# ページ変更視覚化
get '/:name/*/modify.png' do
  name = params[:name]
  title = params[:splat].join('/')
  content_type 'image/png'
  Gyazz::Page.new(name,title).modify_png
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
  Gyazz::Wiki.new(name).rss(app_root)
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
  response["Access-Control-Allow-Origin"] = "*" # 別サイトからのAjaxを許可

  wiki = Gyazz::Wiki.new(name)
  page = Gyazz::Page.new(wiki,title)

  data = page.data(version)

  #
  # 認証ページのときは順番を入れ換える
  #                   完全認証OK  書込み認証OK   完全認証ページ 書込認証ページ
  #                   OK          OK             OK             OK
  #                   OK          NG             OK             OK
  #                   NG          OK             NG             OK
  #                   NG          NG             NG             NG
  #
  #   完全認証ページ  〇          
  #   書込認証ページ  〇
  #
  if !wiki.password_authorized?(request) then
    if title == Gyazz::ALL_AUTH then
      if !Gyazz::Page.new(wiki,Gyazz::ALL_AUTH).cookie_authorized?(request) then
        data['data'] = page.randomtext.sub(/\n+$/,'').split(/\n/)
      end
    elsif title == Gyazz::WRITE_AUTH then
      # puts Gyazz::Page.new(wiki,title).cookie_authorized?(request)
      if !Gyazz::Page.new(wiki,Gyazz::WRITE_AUTH).cookie_authorized?(request) &&
          !Gyazz::Page.new(wiki,Gyazz::ALL_AUTH).cookie_authorized?(request) then
        data['data'] = page.randomtext.sub(/\n+$/,'').split(/\n/)
      end
    end
  end

  data.to_json

  #
  # 新規ページ作成時、大文字小文字を間違えたページが既に作られていないかチェック ... ここでやるべきか?
  # 候補ページを追加してJSONで返すといいのかも?
  # Page.new でやるべきかもしれない
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
end

# ページをテキストデータとして取得
get '/:name/*/text' do
  name = params[:name]
  title = params[:splat].join('/')
  page = Gyazz::Page.new(name,title)
  # なぞなぞ認証できてない場合は並べかえ *******
  cookie_authorized = false
  (!cookie_authorized && page.auth_page?) ? page.randomtext : page.text
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
  @page = Gyazz::Page.new(name,title)
  @version = version
  @write_authorized = true # ここはちゃんとやる ******

  erb :edit
end

#-----------------------------------------------------
# ページ表示関連
#-----------------------------------------------------

# ランダムにページを表示
get "/:name/__random" do |name|
  #  # ここも認証とかランダム化とか必要
  wiki = Gyazz::Wiki.new(name)
  pages = wiki.pages
  len = pages.length
  ignore = len / 2 # 新しい方からignore個は選ばない
  ignore = 0
  @page = pages[ignore + rand(len-ignore)]
  erb :page
end

# ページ表示
get '/:name/*' do
  name = params[:name]               # Wikiの名前   (e.g. masui)
  title = params[:splat].join('/')   # ページの名前 (e.g. TODO)

  @page = Gyazz::Page.new(name,title)
  @page.record_access_history

  #### write_authorizedをここで計算

  erb :page
end
