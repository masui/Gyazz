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

#
# 設定属性
#
def attr(name,key,value=nil)
  ret = nil
  attrdbfile = "#{Gyazz.topdir(name)}/attr.dir"
  if value then # 書込み
    attrdb = SDBM.open(attrdbfile,0644);
    attrdb[key] = value
    attrdb.close
  else
    if File.exist?(attrdbfile) then
      attrdb = SDBM.open(attrdbfile,0644);
      ret = attrdb[key]
      attrdb.close
    end
  end
  ret
end
