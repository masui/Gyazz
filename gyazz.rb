# -*- coding: utf-8 -*-
# -*- ruby -*-

require 'rubygems'
require 'sinatra'
require 'json'
require 'erb'

$: << 'lib'
require 'config'
require 'lib'
require 'related'
require 'search'
require 'writedata'
require 'readdata'
require 'edit'

#
# API
#
# 外に見せないサービスは /__xxx という名前にする
#

get '/:name/*/search' do  # /増井研/合宿/search 
  name = params[:name]
  q = params[:splat].join('/')
  search(name,q)
end

get "/__search/:name" do |name|
  q = params[:q]
  redirect q == '' ? "#{URLROOT}/#{name}" : "#{URLROOT}/#{name}/#{q}/search"
end

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
  title = params[:splat].join('/')   # /a/b/c/text のtitleを"b/c"にする
  readdata(name,title,0)
#  file = datafile(name,title,0)
#  s = File.exist?(file) ? File.read(file)  : ''
#  s =~ /^\s*$/ ? "(empty)" : s
end

get '/:name/*/text/:version' do      # 古いバージョンを取得
  name = params[:name]
  title = params[:splat].join('/')
  version = params[:version].to_i
  readdata(name,title,version)
end

get '/:name/*/edit' do
  name = params[:name]
  title = params[:splat].join('/')   # /a/b/c/text のtitleを"b/c"にする
  edit(name,title)
end

#
# ページ表示
#
get '/:name/*' do
  @name = params[:name]               # Wikiの名前   (e.g. masui)
  @title = params[:splat].join('/')   # ページの名前 (e.g. TODO)
  @urlroot = URLROOT
  @related = related_html(@name,@title)
  erb :page
end

#
# データ書込み 
#
post '/__write' do
  postdata = params[:data].split(/\n/)
  writedata(postdata)
end

