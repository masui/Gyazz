# -*- coding: utf-8 -*-
# -*- ruby -*-

require 'rubygems'
require 'sinatra'
require 'digest/md5'
require 'time'

get '/' do
  redirect "tmpshare.html"
end

get "/:keyword-:password" do |keyword,password|
  redirect "/#{keyword}-#{password}/Index"
  #redirect "http://TmpShare.com/#{keyword}-#{password}/Index"
end

#
# keywords.txt にキーワードとアクセス時刻、作成パスワードを書いていく
#
# masui\tSun Nov 11 14:36:13 +0900 2012\t29adb8650c
#

# expire秒数を指定
get %r{^/([^\/]+)/(\d+)$} do |keyword,expire|
  process(keyword,expire.to_i)
end

get "/:keyword" do |keyword|
  process(keyword,600)
end

def process(keyword,expire)
  time = nil
  hash = nil
  now = Time.now
  if params[:expire] && params[:expire] =~ /^\d+$/ then
    expire = params[:expire].to_i
  end
  if File.exist?("keywords.txt") then
    File.open("keywords.txt"){ |f|
      f.each { |line|
        (k, t, h, e) = line.chomp.split(/\t/)
        if k == keyword then
          tp = Time.parse(t)
          if now - tp < e.to_i then
            time = tp
            hash = h
          end
        end
      }
    }
  end
  if time then
  else
    Digest::MD5.hexdigest(keyword + now.to_s) =~ /.{10}/
    hash = $&
    File.open("keywords.txt","a"){ |f|
      f.puts "#{keyword}\t#{now}\t#{hash}\t#{expire}"
    }
  end

  data = []
  data << "#{keyword}-#{hash}"
  data << "Index"
  data << "このページにファイルをドラッグ/ドロップして共有できます"
  data << "テキストは[[http://Gyazz.com Gyazz]]と同じ方法で編集できます"
  data << "Powered by [[http://TmpShare.com TmpShare.com]]"
  __writedata(data)

  redirect "/#{keyword}-#{hash}/Index"
  # redirect "http://TmpShare.com/#{keyword}-#{hash}/Index"
end

