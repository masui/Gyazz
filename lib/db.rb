# -*- coding: utf-8 -*-
#
# SDBMを使うものを少しずつこちらに移動する (2013/12/23 15:09:22)
#

def repimage(name,title)
  repimage = SDBM.open("#{Gyazz.topdir(name)}/repimage")
  img = repimage[title]
  repimage.close
  img
end

