# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'related'
require 'uploaded'

def page(name,title)
  @name = name
  @title = title
  @urlroot = URLROOT
  @srcroot = SRCROOT
  @related = related_html(@name,@title)
  @uploaded = uploaded_html
  erb :page
end

