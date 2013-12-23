# -*- coding: utf-8 -*-

# アクセス履歴をJSONで返す
#def access(name,title)
#  accessfile = "#{Gyazz.backupdir(name,title)}/access"
#  (File.exist?(accessfile) ? File.open(accessfile).read.split : []).to_json
#end

# 変更履歴をJSONで返す
def modify(name,title)
  dir = Gyazz.backupdir(name,title)
  return '' unless File.exist?(dir)
  Dir.open(dir).find_all { |f|
    f =~ /^\d{14}$/
  }.sort { |a,b|
    a <=> b
  }.push(File.mtime(Gyazz.datafile(name,title)).strftime('%Y%m%d%H%M%S')).to_json
end
