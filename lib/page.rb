# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'related'

def page(name,title)
  @name = name
  @title = title
  @urlroot = URLROOT
  @related = related_html(@name,@title)
  erb :page
end

