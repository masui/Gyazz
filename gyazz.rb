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

get '/:name/*/search' do          # /増井研/合宿/search 
  name = params[:name]
  q = params[:splat].join('/')    # /a/b/c/search の q を"b/c"にする
  search(name,q)
end

get "/__search/:name" do |name|
  q = params[:q]
  redirect q == '' ? "#{URLROOT}/#{name}" : "#{URLROOT}/#{name}/#{q}/search"
end

# データ書込み 

post '/__write' do
  postdata = params[:data].split(/\n/)
  writedata(postdata)
end

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
  attr(name)
end

#
# リスト表示
#

get "/:name" do |name|
  search(name)
end

get "/:name/" do |name|
  search(name)
end

get "/:name/__list" do |name|
  list(name)
end

#
# データテキスト取得
#

get '/:name/*/text' do
  name = params[:name]
  title = params[:splat].join('/')
  readdata(name,title,0)
end

get '/:name/*/text/:version' do      # 古いバージョンを取得
  name = params[:name]
  title = params[:splat].join('/')
  version = params[:version].to_i
  readdata(name,title,version)
end

#
# 編集モード
#

get '/:name/*/edit' do
  name = params[:name]
  title = params[:splat].join('/')
  redirect "/#{name}/#{title}"
end

get '/:name/*/__edit' do
  name = params[:name]
  title = params[:splat].join('/')
  edit(name,title)
end

get '/:name/*/__edit/:version' do       # 古いバージョンを編集
  name = params[:name]
  title = params[:splat].join('/')
  version = params[:version].to_i
  edit(name,title,version)
end

#
# ページ表示
#

get '/:name/*' do
  name = params[:name]               # Wikiの名前   (e.g. masui)
  title = params[:splat].join('/')   # ページの名前 (e.g. TODO)
  page(name,title)
end


