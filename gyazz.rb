# -*- coding: utf-8 -*-
# -*- ruby -*-

require 'rubygems'
require 'sinatra'

$: << 'lib'
require 'config'
require 'search'
require 'writedata'
require 'readdata'
require 'edit'
require 'page'

#
# API
#
# 外に見せないサービスは /__xxx という名前にする
#

get '/:name/*/search' do  # /増井研/合宿/search 
  name = params[:name]
  q = params[:splat].join('/')   # /a/b/c/search の q を"b/c"にする
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

# Gyazoへの転送!

get %r{/__gyazoupload/([0-9a-f]+)/(.*)} do |id,url|
  File.open("/tmp/data","w"){ |f|
    f.puts "#{id}//#{url}"
  }
  redirect url
end

###########################

get "/:name" do |name|
  search(name)
end

get "/:name/" do |name|
  search(name)
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

# 編集

get '/:name/*/edit' do
  name = params[:name]
  title = params[:splat].join('/')
  edit(name,title)
end

get '/:name/*/edit/:version' do       # 古いバージョンを編集
  name = params[:name]
  title = params[:splat].join('/')
  version = params[:version].to_i
  edit(name,title,version)
end

# ページ表示

get '/:name/*' do
  name = params[:name]               # Wikiの名前   (e.g. masui)
  title = params[:splat].join('/')   # ページの名前 (e.g. TODO)
  page(name,title)
end


