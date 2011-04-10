# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'related'
require 'uploaded'

def page(name,title)
  attr = SDBM.open("#{topdir(name)}/attr",0644);
  searchable = (attr['searchable'] == 'true' ? true : false)
  @robotspec = (searchable ? "index,follow" : "noindex,nofollow")
  attr.close

  if File.exist?(datafile(name,title)) then
    @rawdata = File.read(datafile(name,title))
  end

  @name = name
  @title = title
  @urlroot = URLROOT
  @srcroot = SRCROOT
  @related = related_html(@name,@title)
  @uploaded = uploaded_html
  erb :page
end

