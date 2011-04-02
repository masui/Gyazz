# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'sdbm'
require 'pair'

def writedata(data)
  # Wiki名/タイトル/ブラウザの前MD5値/新規データが送られる


  wikiname = data.shift
  pagetitle = data.shift
  browser_md5 = data.shift
  newdata = data.join("\n")+"\n"            # newdata: 新規書込みデータ

  curfile = datafile(wikiname,pagetitle,0)
  server_md5 = ""
  curdata = ""
  if File.exist?(curfile) then
    curdata = File.read(curfile)
    server_md5 = md5(curdata)
  end                                       # curdata: Web上の最新データ

  # バックアップディレクトリを作成
  Dir.mkdir(backupdir(wikiname)) unless File.exist?(backupdir(wikiname))
  Dir.mkdir(backupdir(wikiname,pagetitle)) unless File.exist?(backupdir(wikiname,pagetitle))

  # 最新データをバックアップ
  if curdata != "" && curdata != newdata then
    File.open(newbackupfile(wikiname,pagetitle),'w'){ |f|
      f.print(curdata)
    }
  end

  if server_md5 == browser_md5 then
    File.open(curfile,"w"){ |f|
      f.print(newdata)
    }
    status = 'noconflict'
  else
    # ブラウザが指定したMD5のファイルを捜す
    oldfile = backupfiles(wikiname,pagetitle).find { |f|
      md5(File.read(f)) == browser_md5
    }
    if oldfile then
      newfile = "/tmp/newfile#{$$}"
      patchfile = "/tmp/patchfile#{$$}"
      File.open(newfile,"w"){ |f|
        f.print newdata
      }
      system "diff -c #{oldfile} #{newfile} > #{patchfile}"
      system "patch #{curfile} < #{patchfile}"
      File.delete newfile, patchfile
    else
      File.open(curfile,"w"){ |f|
        f.print newdata
      }
    end
    status = 'conflict'
  end

  # タイムスタンプ保存
  timestamp = Time.now.strftime('%Y%m%d%H%M%S')
  dbm = SDBM.open("#{backupdir(wikiname)}/timestamp",0644)
  data.each { |line|
    l = line.sub(/^\s*/,'')
    if !dbm[l] then
      dbm[l] = timestamp
    end
  }
  dbm.close

  # リンク情報更新
  pair = Pair.new("#{topdir(wikiname)}/pair")
  curdata.keywords.each { |keyword|
    pair.delete(pagetitle,keyword)
  }
  newdata.keywords.each { |keyword|
    pair.add(pagetitle,keyword)
  }

  # 代表画像
  repimage = SDBM.open("#{topdir(wikiname)}/repimage")
  if data[0] =~ /gyazo.com\/(\w{32})\.png/i then
    repimage[pagetitle] = $1
  else
    repimage.delete(pagetitle)
  end

  status # 'conflict' or 'noconflict'
end

