# -*- coding: utf-8 -*-

require 'config'
require 'lib'

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
  erb :edit
end

