# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'auth'

def edit(name,title,version=0)
  @name = name
  @title = title
  @urltop = topurl(name)
  @urlroot = app_root
  file = datafile(name,title,version)
  @text = File.exist?(file) ? File.read(file)  : ''
  # @text =~ /^\s*$/ ? "(empty)" : @text
  @text.gsub!(/&/,'&amp;') # 2012/04/23 04:44:29 masui ????
  @text.gsub!(/</,'&lt;') # 2012/10/24 14:32:15 masui
  @orig_md5 = md5(@text) # 2012/5/3 masui
  @write_authorized = false
  @write_authorized = true if password_authorized?(name)
  @write_authorized = true if cookie_authorized?(name,ALL_AUTH)
  @write_authorized = true if cookie_authorized?(name,WRITE_AUTH)

  erb :edit
end

