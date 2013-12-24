# -*- coding: utf-8 -*-

# require 'sdbm'
# require 'set'
# require 'db'

def writedata(name,title,data,browser_md5 = nil)
  # ブラウザからの要求のときはbrowser_md5に値がセットされる
  # gyazz-ruby のAPIや強制書込みの場合はbrowser_md5はセットされない
  
  newdata = data.sub(/\n+$/,'')+"\n"      # newdata: 新規書込みデータ

  curfile = Gyazz.datafile(name,title,0)
  server_md5 = ""
  curdata = ""
  if File.exist?(curfile) then
    curdata = File.read(curfile).sub(/\n+$/,'')+"\n"
    server_md5 = Gyazz.md5(curdata)
  end                                 # curdata: Web上の最新データ

  # バックアップディレクトリを作成
  Dir.mkdir(Gyazz.backupdir(name)) unless File.exist?(Gyazz.backupdir(name))
  Dir.mkdir(Gyazz.backupdir(name,title)) unless File.exist?(Gyazz.backupdir(name,title))

  # 最新データをバックアップ
  if curdata != "" && curdata != newdata then
    File.open(Gyazz.newbackupfile(name,title),'w'){ |f|
      f.print(curdata)
    }
  end

  if server_md5 == browser_md5 || curdata == '' || browser_md5.nil? then
    File.open(curfile,"w"){ |f|
      f.print(newdata)
    }
    status = 'noconflict'
  else
    # ブラウザが指定したMD5のファイルを捜す
    oldfile = Gyazz.backupfiles(name,title).find { |f|
      Gyazz.md5(File.read(f)) == browser_md5
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
      status = 'conflict'
    else
      File.open(curfile,"w"){ |f|
        f.print newdata
      }
      status = 'noconflict'
    end
    #status = 'conflict'
  end

  # 各行のタイムスタンプ保存
  timestr = Time.now.strftime('%Y%m%d%H%M%S')
  data.split(/\n/).each { |line|
    l = line.sub(/^\s*/,'')
    if !line_timestamp(name,title,l) then
      line_timestamp(name,title,l,timestr)
    end
  }

  # リンク情報更新
  pair = Pair.new("#{Gyazz.topdir(name)}/pair")
  curdata.keywords.each { |keyword|
    pair.delete(title,keyword)
  }
  newdata.keywords.each { |keyword|
    pair.add(title,keyword)
  }
  pair.close

  # 書込みのたびにリンク情報を完全に更新しようとしたコード。
  # 遅いのでとりあえず消しておく
  #
  #  # リンク情報更新
  #  pair = Pair.new("#{topdir(name)}/pair")
  #  links = pair.collect(title) # 定義されているリンク全部
  #  links.each { |link| # とりあえず全部消す
  #    pair.delete(title,link)
  #  }
  #  #curdata.keywords.each { |keyword|
  #  #pair.delete(title,keyword)
  #  #}
  #  links.each { |link| # 定義されてたリンク先からのリンクを全部再確認して追加
  #    File.read(datafile(name,link)).keywords.each { |keyword|
  #      if keyword == title then
  #        pair.add(link,keyword)
  #      end
  #    }
  #  }
  #  newdata.keywords.each { |keyword|
  #    pair.add(title,keyword)
  #  }
  #  pair.close

  # 代表画像
  firstline = data.split(/\n/)[0]
  if firstline =~ /gyazo.com\/(\w{32})\.png/i then
    repimage(name,title,$1)
  elsif firstline =~ /(https?:\/\/.+)\.(png|jpe?g|gif)/i
    repimage(name,title,"#{$1}.#{$2}")
  else
    repimage(name,title,'')
  end

  status # 'conflict' or 'noconflict'
end

