# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'sdbm'
require 'pair'
require 'set'

def writable?(name,gyazoid)
  attr = SDBM.open("#{topdir(name)}/attr",0644);
  return true if attr['protected'] != 'true'

  gyazoids = Set.new
  imageid = SDBM.open("#{FILEROOT}/imageid",0644)
  Dir.open(topdir(name)).each { |f|
    if f =~ /^[0-9a-f]{32}$/ then
      filename = "#{topdir(name)}/#{f}"
      if File.file?(filename) then
        File.open(filename){ |f|
          f.each { |line|
            while line.sub!(/http:\/\/gyazo.com\/([0-9a-f]{32}).png/,'') do
              iid = $1
              if imageid[iid] then
                gyazoids.add(imageid[iid])
              end
            end
          }
        }
      end
    end
  }
  gyazoids.member?(gyazoid)
end

def writedata(data)
  # Wiki名/タイトル/ブラウザの前MD5値/新規データが送られる

  name = data.shift
  title = data.shift
  browser_md5 = data.shift
  newdata = data.join("\n")+"\n"      # newdata: 新規書込みデータ

  gyazoid = request.cookies["GyazoID"]
  if !writable?(name, gyazoid) then
    return "protected"
  end

  curfile = datafile(name,title,0)
  server_md5 = ""
  curdata = ""
  if File.exist?(curfile) then
    curdata = File.read(curfile)
    server_md5 = md5(curdata)
  end                                 # curdata: Web上の最新データ

  # バックアップディレクトリを作成
  Dir.mkdir(backupdir(name)) unless File.exist?(backupdir(name))
  Dir.mkdir(backupdir(name,title)) unless File.exist?(backupdir(name,title))

  # 最新データをバックアップ
  if curdata != "" && curdata != newdata then
    File.open(newbackupfile(name,title),'w'){ |f|
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
    oldfile = backupfiles(name,title).find { |f|
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

  # 各行のタイムスタンプ保存
  timestamp = Time.now.strftime('%Y%m%d%H%M%S')
  dbm = SDBM.open("#{backupdir(name,title)}/timestamp",0644)
  data.each { |line|
    l = line.sub(/^\s*/,'')
    if !dbm[l] then
      dbm[l] = timestamp
    end
  }
  dbm.close

  # リンク情報更新
  pair = Pair.new("#{topdir(name)}/pair")
  curdata.keywords.each { |keyword|
    pair.delete(title,keyword)
  }
  newdata.keywords.each { |keyword|
    pair.add(title,keyword)
  }

  # 代表画像
  repimage = SDBM.open("#{topdir(name)}/repimage")
  if data[0] =~ /gyazo.com\/(\w{32})\.png/i then
    repimage[title] = $1
  else
    repimage.delete(title)
  end

  status # 'conflict' or 'noconflict'
end

