# -*- coding: utf-8 -*-

require 'config'
require 'lib'

def edit(name,title)
  @name = name
  @title = title
  @urltop = topurl(name)
  @urlroot = URLROOT
  file = datafile(name,title,0)
  @text = File.exist?(file) ? File.read(file)  : ''
  @text =~ /^\s*$/ ? "(empty)" : @text
  erb :edit
end

