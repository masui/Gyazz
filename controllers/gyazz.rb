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
set :session_secret, Gyazz::SESSION_SECRET # 塩

configure do
  set :protection, :except => :frame_options
end

#before '/:name/*' do
before '/:name*' do
  name = params[:name]
  title = params[:splat][0]

  pass if title.index(Gyazz::ALL_AUTH) == 0
  pass if title.index(Gyazz::WRITE_AUTH) == 0
  pass if title == 'rss.xml'
  #
  # 認証が存在しないか、パスワード認証に成功してるか、なぞなぞ認証に成功してればOK
  #
  wiki = Gyazz::Wiki.new(name)
  authorized = true
  if wiki.password_required? || wiki.all_auth_page.exist? then
    authorized = false
    authorized = true if wiki.password_authorized?(request)
    authorized = true if wiki.all_auth_page.cookie_authorized?(request)
  end

  if !authorized
    if wiki.password_required? then
      response['WWW-Authenticate'] = %(Basic realm="#{name}")
      throw(:halt, [401, "Not authorized.\n"])
    else
      throw(:halt, [401, "Not authorized.\n"])
    end
  end
end

get '/' do
  redirect URI.encode("#{Gyazz::DEFAULTPAGE}")
end

#-----------------------------------------------------
# リスト表示 / 検索
#-----------------------------------------------------

get "/__search/:name" do |name|
  q = params[:q]
  if q == '' then
    redirect URI.encode("/#{name}")
  else
    @wiki = Gyazz::Wiki.new(name)
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

post '/__write__' do # 無条件書き込み (gyazz-rubyで利用)
  data = params[:data]
  name = params[:name]
  title = params[:title]
  if !data or name.to_s.empty? or title.to_s.empty?
    halt 400, 'Bad Request: parameter "data", "name", "title" require'
  end
  Gyazz::Page.new(name,title).write(data)
end

get '/__write__' do # 無条件書き込み
  data = params[:data]
  name = params[:name]
  title = params[:title]
  if !data or name.to_s.empty? or title.to_s.empty?
    halt 400, 'Bad Request: parameter "data", "name", "title" require'
  end
  Gyazz::Page.new(name,title).write(data)
  redirect("/#{name}/#{title}")
end

# 認証の考え方は auth.rb を参照

# なぞなぞ認証チャレンジ文字列取得
post '/__tellauth' do
  name = params[:name]
  title = params[:title]
  useranswer = params[:authstr]
  page = Gyazz::Page.new(name,title)
  if page.is_auth_page? then
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
    savepath = "#{Gyazz::FILEROOT}/upload/#{savefile}"
    File.open(savepath, 'wb'){ |f| f.write(file_contents) }

    savefile
  end
end

# アップロードされたファイルにアクセス
get "/upload/:filename" do |filename|
  send_file "#{Gyazz::FILEROOT}/upload/#{filename}"
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
  puts "#{key} ==> #{val}"
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
  puts @pages
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

## ページの代表画像があればリダイレクトする *******
get '/:name/*/icon' do
  name = params[:name]
  title = params[:splat].join('/')
  page = Gyazz::Page.new(name,title)
  image = page['repimage']
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

# 古いバージョンのJSONを取得
get '/:name/*/json' do
  name = params[:name]
  title = params[:splat].join('/')
  version = params[:version]
  age = params[:age]
  response["Access-Control-Allow-Origin"] = "*" # 別サイトからのAjaxを許可

  wiki = Gyazz::Wiki.new(name)
  page = Gyazz::Page.new(wiki,title)

  if age then # 指定されたageレベルの古さのデータを取得
    vts = page.vis_timestamp(age.to_i)
    version = 0
    page.modify_history.reverse.each { |timestamp|
      break if timestamp < vts
      version += 1
    }
    data = page.data(version)
  else
    data = page.data(version.to_s.to_i)
  end

  # 未認証状態でなぞなぞページにアクセスしたときはテキストを並べかえる

  if !page.is_all_auth_page? && !page.is_write_auth_page? then
    # 認証問題ページでなければ問題なし
  else
    if wiki.password_authorized?(request) then
      # パスワード認証成功してるときは問題なし
    else
      if wiki.all_auth_page.exist? && wiki.all_auth_page.cookie_authorized?(request) then
        # 完全認証なぞなぞに答えてるときは問題なし
      else
        if page.is_write_auth_page? && wiki.write_auth_page.cookie_authorized?(request)
          # 書込認証なぞなぞに答えたときはそのページは問題なし
        else
          data['data'] = page.randomtext.sub(/\n+$/,'').split(/\n/)
        end
      end
    end
  end
  
  data.to_json
end

# ページをテキストデータとして取得
get '/:name/*/text' do
  name = params[:name]
  title = params[:splat].join('/')
  wiki = Gyazz::Wiki.new(name)
  page = Gyazz::Page.new(name,title)

  # なぞなぞ認証できてない場合は並べかえ
  text = page.text
  if !page.is_all_auth_page? && !page.is_write_auth_page? then
    # 認証問題ページでなければ問題なし
  else
    if wiki.password_authorized?(request) then
      # パスワード認証成功してるときは問題なし
    else
      if wiki.all_auth_page.cookie_authorized?(request) then
        # 完全認証なぞなぞに答えてるときは問題なし
      else
        if page.is_write_auth_page? && wiki.write_auth_page.cookie_authorized?(request)
          # 書込認証なぞなぞに答えたときはそのページは問題なし
        else
          text = page.randomtext
        end
      end
    end
  end
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
end

#-----------------------------------------------------
# 編集モード
#-----------------------------------------------------

get '/:name/*/__edit' do
  name = params[:name]
  title = params[:splat].join('/')
  redirect URI.encode("#{name}/#{title}/__edit/0")
end

get '/:name/*/__edit/:version' do       # 古いバージョンを編集
  name = params[:name]
  title = params[:splat].join('/')
  version = params[:version].to_i
  wiki = Gyazz::Wiki.new(name)
  page = Gyazz::Page.new(wiki,title)
  page['version'] = version.to_s
  page['writable'] = writable?(wiki,request).to_s

  @page = page
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
  @page['writable'] = writable?(wiki,request).to_s

  erb :page
end

# ページ表示
get '/:name/*' do
  name = params[:name]               # Wikiの名前   (e.g. masui)
  title = params[:splat].join('/')   # ページの名前 (e.g. TODO)

  wiki = Gyazz::Wiki.new(name)
  page = Gyazz::Page.new(wiki,title)
  page.record_access_history
  page['writable'] = writable?(wiki,request).to_s

  @page = page
  erb :page
end
