# -*- coding: utf-8 -*-

require 'config'
require 'lib'

# アクセス履歴をJSONで返す

def access(name,title)
  accessfile = "#{backupdir(name,title)}/access"
  accessdata = []
  accessdata = File.open(accessfile).read if File.exist?(accessfile)
  "[\n" +
    accessdata.collect { |line|
      "\"#{line.chomp}\""
    }.join(",\n") +
    "\n]\n"
end

