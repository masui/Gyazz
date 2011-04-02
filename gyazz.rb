# -*- coding: utf-8 -*-
# -*- ruby -*-

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

#
# データテキスト取得
#

get '/:name/*/text' do
  name = params[:name]
  title = params[:splat].join('/')   # /a/b/c/text のtitleを"b/c"にする
  file = datafile(name,title,0)
  File.exist?(file) ? File.read(file) : "(empty)"
end

get '/:name/*/text/:version' do      # 古いバージョンを取得
  name = params[:name]
  version = params[:version].to_i
  title = params[:splat].join('/')
  file = datafile(name,title,version)
  datestr = ""
  if version > 0 then
    file =~ /\/(\d{14})$/
    datestr = $1
  end
  datestr + "\n" + (File.exist?(file) ? File.read(file) : "(empty)")
end

#
# ページ表示
#
get '/:name/*' do
  @name = params[:name]               # Wikiの名前   (e.g. masui)
  @title = params[:splat].join('/')   # ページの名前 (e.g. TODO)
  @root = URLROOT
  @related = related_html(@name,@title)
  erb :page
end

#
# データ書込み 
#
post '/post' do
  data = params[:data]
  data = data.split(/\n/)
  name = data.shift
  title = data.shift
  browser_md5 = data.shift
  file = datafile(name,title,0)
  server_md5 = md5(File.read(file))

  Dir.mkdir(backupdir(name)) unless File.exist?(backupdir(name))
  Dir.mkdir(backupdir(name,title)) unless File.exist?(backupdir(name,title))
  newdata = data.join("\n")
  if File.exist?(file) then
    curdata = File.read(file)
    if curdata != newdata then
      File.open(newbackupfile(name,title),'w'){ |f|
        f.puts(curdata)
      }
      File.open(file,"w"){ |f|
        f.puts(newdata)
      }
    end
  end

  if server_md5 == browser_md5 then
    'noconflict'
  else
    # ブラウザが指定したMD5のファイルを捜す
    oldfile = backupfiles(name,title).find { |f|
      md5(File.read(f)) == browser_md5
    }
    if oldfile then
      # diff old new > patch
      # patch curr < patch
      newfile = "/tmp/newfile"
      File.open(newfile,"w"){ |f|
        f.puts newdata
      }
      # oldfile = datafile(name,title,0)
      system "diff #{oldfile} #{newfile} > /tmp/patchdata"
      curfile = datafile(name,title,0)
      system "patch #{curfile} < /tmp/patchdata"
    end

    'conflict'
  end
end


