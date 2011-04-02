# -*- coding: utf-8 -*-

require 'config'
require 'lib'

def readdata(name,title,version=0)
  file = datafile(name,title,version)
  datestr = ""
  if version > 0 then
    file =~ /\/(\d{14})$/
    datestr = $1
  end
  data = File.exist?(file) ? File.read(file)  : ''

  if version > 0 then
    dbm = SDBM.open("#{backupdir(name,title)}/timestamp",0644)
    a = ''
    data.each_line { |line|
      l = line.chomp
      ll = l.sub(/^\s*/,'')
      dbm[ll] =~ /(....)(..)(..)(..)(..)(..)/
      t = Time.local($1.to_i,$2.to_i,$3.to_i,$4.to_i,$5.to_i,$6.to_i)
      td = (Time.now - t).to_i
      a += "#{l} #{td}\n"
    }
    dbm.close
    data = a
  end

  s = data.gsub(/[\s\r\n]/,'')
  if s.length == 0 then
    data = '(empty)'
  end

  datestr + "\n" + data
end

