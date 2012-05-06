# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'auth'

def edit(name,title,version=0)
  @name = name
  @title = title
  @urltop = topurl(name)
  @urlroot = URLROOT
  @srcroot = SRCROOT
  file = datafile(name,title,version)
  @text = File.exist?(file) ? File.read(file)  : ''
  # @text =~ /^\s*$/ ? "(empty)" : @text
  @text.gsub!(/&/,'&amp;') # 2012/04/23 04:44:29 masui ????
  @orig_md5 = md5(@text) # 2012/5/3 masui
  @write_authorized = (write_authorized?(name) ? true : false)

  erb :edit
end

