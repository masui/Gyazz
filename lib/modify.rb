# -*- coding: utf-8 -*-

require 'config'
require 'lib'

# 変更履歴をJSONで返す

def modify(name,title)
  backups = []
  if File.exist?(backupdir(name,title)) then
    Dir.open(backupdir(name,title)).each { |f|
      backups << f if f =~ /^.{14}$/
    }
  end
  backups = backups.sort { |a,b|
    a <=> b
  }
  backups.push(File.mtime(datafile(name,title)).strftime('%Y%m%d%H%M%S'))
  "[\n" +
    backups.collect { |line|
      "\"#{line.chomp}\""
    }.join(",\n") +
    "\n]\n"
end

