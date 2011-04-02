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
  # Wiki名/タイトル/ブラウザの前MD5値/新規データが送られる
  postdata = params[:data].split(/\n/)
  wikiname = postdata.shift
  pagetitle = postdata.shift
  browser_md5 = postdata.shift
  newdata = postdata.join("\n")+"\n"

  curfile = datafile(wikiname,pagetitle,0)
  server_md5 = ""
  curdata = ""
  if File.exist?(curfile) then
    curdata = File.read(curfile)
    server_md5 = md5(curdata)
  end

  Dir.mkdir(backupdir(wikiname)) unless File.exist?(backupdir(wikiname))
  Dir.mkdir(backupdir(wikiname,pagetitle)) unless File.exist?(backupdir(wikiname,pagetitle))

  if curdata != "" && curdata != newdata then
    File.open(newbackupfile(wikiname,pagetitle),'w'){ |f|
      f.print(curdata)
    }
  end

  if server_md5 == browser_md5 then
    File.open(curfile,"w"){ |f|
      f.print(newdata)
    }
    'noconflict'
  else
    # ブラウザが指定したMD5のファイルを捜す
    oldfile = backupfiles(wikiname,pagetitle).find { |f|
      md5(File.read(f)) == browser_md5
    }
    if oldfile then
      newfile = "/tmp/newfile#{$$}"
      patchfile = "/tmp/patchfile#{$$}"
      File.open(newfile,"w"){ |f|
        f.print newdata
      }
      system "diff -c #{oldfile} #{newfile} > #{patchfile}"
      system "patch #{curfile} < #{patchfile}"
      File.delete newfile, patchfile
    else
      File.open(curfile,"w"){ |f|
        f.print newdata
      }
    end
    'conflict'
  end
end

