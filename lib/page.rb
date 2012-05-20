# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'related'
require 'auth'

def page(name,title,write_authorized)
  allaccess = SDBM.open("#{FILEROOT}/access",0644);
  s = "#{name}(#{md5(name)})/#{title}(#{md5(title)})"
  allaccess[s] = (allaccess[s].to_i + 1).to_s
  allaccess.close

  searchable = false
  if File.exist?("#{topdir(name)}/attr.dir") then
    attr = SDBM.open("#{topdir(name)}/attr",0644);
    searchable = (attr['searchable'] == 'true' ? true : false)
    attr.close
  end
  @robotspec = (searchable ? "index,follow" : "noindex,nofollow")

  @do_auth = false
  data_file = datafile(name,title)
  if File.exist?(data_file) then
    @rawdata = File.read(data_file)
    if title == ALL_AUTH then
      if !cookie_authorized?(name,ALL_AUTH) then
        @rawdata = randomize(@rawdata)
        @do_auth = true
      end
    elsif title == WRITE_AUTH then
      if !cookie_authorized?(name,WRITE_AUTH) then
        @rawdata = randomize(@rawdata)
        @do_auth = true
      end
    end
  end
  @write_authorized = write_authorized

  #
  # アクセス履歴をバックアップディレクトリに保存
  # ちょっと変だがとりあえず...
  # readdata() でやるよりここの方がよいようだ (2012/04/14 13:45:53)
  #
  if File.exists?("#{backupdir(name,title)}") then
    File.open("#{backupdir(name,title)}/access","a"){ |f|
      f.puts Time.now.strftime('%Y%m%d%H%M%S')
    }
  end

  @name = name
  @title = title
  @urlroot = URLROOT
  @srcroot = SRCROOT
  @related = related_html(@name,@title)
  erb :page
end

