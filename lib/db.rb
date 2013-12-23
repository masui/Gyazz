# -*- coding: utf-8 -*-
#
# SDBMを使うものを少しずつこちらに移動する (2013/12/23 15:09:22)
#

def repimage(name,title,image=nil)
  db = SDBM.open("#{Gyazz.topdir(name)}/repimage")
  if image then
    db[title] = image
  else
    image = db[title]
  end
  db.close
  image
end

