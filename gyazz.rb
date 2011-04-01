# -*- coding: utf-8 -*-
# -*- ruby -*-

# Sinatra解説
# http://www.sinatrarb.com/intro-jp.html

require 'rubygems'
require 'sinatra'
require 'json'
require 'erb'

$: << 'lib'
require 'config'
require 'related'

#
# API
#

#get '/:name/:title/related' do |name,title|
#  related(name,title).to_json
#end

#
# 関連ページのアイコンのリストHTMLを返す
#
#get '/:name/:title/related_html' do |name,title|
#  @related_html = related_html(name,title)
#  erb :related
#end

#
# データテキスト取得
#

get '/:name/*/text' do
  name = params[:name]
  title = params[:splat].join('/')   # /a/b/c/text のtitleを"b/c"にする
  file = datafile(name,title)
  File.exist?(file) ? File.read(file) : "(empty)"
end

#get '/:name/:title/text' do |name,title|
#  file = datafile(name,title)
#  File.exist?(file) ? File.read(file) : "(empty)"
#end
#
#get '/:name/:title1/:title2/text' do |name,title1,title2|
#  file = datafile(name,"#{title1}/#{title2}")
#  File.exist?(file) ? File.read(file) : "(empty)"
#end

post '/post' do
  File.open("/tmp/log","w"){ |f|
    f.puts params[:data]
  }
  'xxx'
end

#
# ページ表示
#
get '/:name/*' do
  @name = params[:name]             # Wikiの名前   (e.g. masui)
  @title = params[:splat].join('/') # ページの名前 (e.g. TODO)
  @root = URLROOT
  @related = related_html(@name,@title)
  erb :page
end

#get '/:name/:title' do |name,title|
#  @name = name          # Wikiの名前   (e.g. masui)
#  @title = title        # ページの名前 (e.g. TODO)
#  @root = URLROOT
#  @related = related_html(@name,@title)
#  erb :page
#end
#
#get '/:name/:title1/:title2' do |name,title1,title2|
#  @name = name          # Wikiの名前   (e.g. masui)
#  @title = "#{title1}/#{title2}"        # ページの名前 (e.g. TODO)
#  @root = URLROOT
#  @related = related_html(@name,@title)
#  erb :page
#end

