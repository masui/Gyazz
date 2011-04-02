# -*- coding: utf-8 -*-

require 'config'
require 'lib'

def readdata(name,title,version)
  file = datafile(name,title,version)
  datestr = ""
  if version > 0 then
    file =~ /\/(\d{14})$/
    datestr = $1
  end
  s = File.exist?(file) ? File.read(file)  : ''
  s = "(empty)" if s =~ /^\s*$/
  datestr + "\n" + s
end
