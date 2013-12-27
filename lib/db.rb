# -*- coding: utf-8 -*-
#
# SDBMを使うものを少しずつこちらに移動する (2013/12/23 15:09:22)
#

#
# 行のタイムスタンプ
#
def line_timestamp(name,title,line,val=nil)
  db = SDBM.open("#{Gyazz.backupdir(name,title)}/timestamp",0644)
  if val then
    db[line] = val
  else
    val = db[line]
  end
  db.close
  val
end
