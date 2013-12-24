# -*- coding: utf-8 -*-
#
# SDBMを使うものを少しずつこちらに移動する (2013/12/23 15:09:22)
#

#
# Gyazzページの代表画像
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

#
# 全ページのアクセス数
#
def access_count(name,title,value=nil)
  access = SDBM.open("#{FILEROOT}/access",0644);
  key = "#{name}(#{Gyazz.md5(name)})/#{title}(#{Gyazz.md5(title)})"
  if value then
    access[key] = value.to_s
  else
    access[key]
  end
  value = access[key]
  access.close
  value.to_i
end

def searchable(name)
  db = "#{Gyazz.topdir(name)}/attr.dir"
  ret = false
  if File.exist?(db) then
    attr = SDBM.open(db,0644);
    ret = (attr['searchable'] == 'true' ? true : false)
    attr.close
  end
  ret
end
