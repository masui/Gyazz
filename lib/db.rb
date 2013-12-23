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
# ページのアクセス数をトップディレクトリに書く
#
def accesscount(name,title,value=nil)
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
# ページのアクセス履歴
#
def accesshistory(name,title,append=nil)
  if append then # 追記
    if File.exists?("#{Gyazz.backupdir(name,title)}") then
      File.open("#{Gyazz.backupdir(name,title)}/access","a"){ |f|
        f.puts Time.now.strftime('%Y%m%d%H%M%S')
      }
    end
  else
    accessfile = "#{Gyazz.backupdir(name,title)}/access"
    (File.exist?(accessfile) ? File.open(accessfile).read.split : [])
  end
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
