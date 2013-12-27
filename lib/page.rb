# -*- coding: utf-8 -*-

module Gyazz
  class Page
    def initialize(wiki,title)
      puts "Page: wiki=#{wiki}, title=#{title}"
      @wiki = wiki
      if wiki.class == String
        @wiki = Wiki.new(wiki)
      end

      @title = title
      @id = title.md5
      Gyazz.id2title(@id,title) # titleとIDとの対応セット

      @timestamp = SDBM.open("#{dir}/timestamp",0644) # 行のタイムスタンプ
      @attr = {}
      @attr['do_auth'] = 'false'
      @attr['write_authorized'] = 'true'
    end
    attr :wiki
    attr :title
    attr :attr
    attr :timestamp
    attr :id

    def dir
      dir = "#{@wiki.dir}/#{@id}"
      Dir.mkdir(dir) unless File.exist?(dir)
      dir
    end
    
    def curfile # 現在編集中のファイル
      "#{dir}/curfile"
    end

    def curdata
      File.exist?(curfile) ? File.read(curfile) : ''
    end

    def datafile(version=0)
      version = version.to_i
      if version == 0 then
        curfile
      else
        files = [curfile]
        files += backupfiles
        if version >= files.length then
          version = files.length-1
        end
        files[version]
      end
    end

    def text(version=0)
      file = datafile(version)
      s = (File.exist?(file) ? File.read(file)  : '')
      s.sub(/\s+$/,'')
    end
    
    def write(data,browser_md5=nil)
      # ブラウザからの要求のときはbrowser_md5に値がセットされる
      # gyazz-ruby のAPIや強制書込みの場合はbrowser_md5はセットされない
  
      newdata = data.sub(/\n+$/,'')+"\n"      # newdata: 新規書込みデータ

      # 最新データをバックアップ
      if curdata != "" && curdata != newdata then
        File.open("#{dir}/#{Time.now.stamp}",'w'){ |f|
          f.print(curdata)
        }
      end

      if curdata.md5 == browser_md5 || curdata == '' || browser_md5.nil? then
        File.open(curfile,"w"){ |f|
          f.print(newdata)
        }
        status = 'noconflict'
      else
        # ブラウザが指定したMD5のファイルを捜す
        oldfile = backupfiles.find { |f|
          File.read(f).md5 == browser_md5
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
      end

      # 各行のタイムスタンプ保存
      data.split(/\n/).each { |line|
        l = line.sub(/^\s*/,'')
        if !timestamp[l] then
          timestamp[l] = Time.now.stamp
        end
      }

      # リンク情報更新
      pair = Pair.new("#{@wiki.dir}/pair")
      curdata.keywords.each { |keyword|
        pair.delete(title,keyword)
      }
      newdata.keywords.each { |keyword|
        pair.add(title,keyword)
      }
      pair.close

      # 代表画像
      firstline = data.split(/\n/)[0]
      if firstline =~ /gyazo.com\/(\w{32})\.png/i then
        self.repimage = $1
      elsif firstline =~ /(https?:\/\/.+)\.(png|jpe?g|gif)/i
        self.repimage = "#{$1}.#{$2}"
      else
        self.repimage= ''
      end

      status # 'conflict' or 'noconflict'
    end

    def data(version=nil) # erbに渡すための情報を付加
      file = datafile(version)
      ret = {}
      datestr = ""
      if version && version > 0 then
        file =~ /\/(\d{14})$/
        ret['date'] = $1
      end
      d = text(version).sub(/\n+$/,'').split(/\n/)
      ret['data'] = d
      if version && version > 0 then
        ret['age'] = d.collect { |line|
          line = line.chomp.sub(/^\s*/,'')
          t = timestamp[line].to_time
          (Time.now - t).to_i
        }
      end
      ret
    end

    def backupids
      Dir.open(dir).find_all { |f|
        f =~ /^\d{14}$/
      }.sort{ |a,b|
        b <=> a
      }
    end

    def backupfiles
      backupids.collect { |backkupid|
        "#{dir}/#{backupid}"
      }
    end

    def access # ページへのアクセス時刻を記録
      File.open("#{dir}/access","a"){ |f|
        f.puts Time.now.stamp
      }
    end

    def access_history
      accessfile = "#{dir}/access"
      (File.exist?(accessfile) ? File.read(accessfile).split : [])
    end

    def repimage
      repimagefile = "#{dir}/repimage"
      image = nil
      if File.exist?(repimagefile) then
        image = File.read(repimagefile).chomp
      end
      image
    end
    
    def repimage=(image)
      repimagefile = "#{dir}/repimage"
      File.open(repimagefile,"w"){ |f|
        f.puts image
      }
      image
    end

    def modtime
      File.mtime(curfile)
    end
    
    def modify_history
      backupids.push(modtime.stamp)
    end

    def createtime
      if backupids[0] then
        backupids[0].to_time 
      else
        File.mtime(curfile)
      end
    end

    def accesstime
      access_history.last.to_s
    end

    def related_pages
      related_titles(@wiki.name,@title).collect { |title|
        Gyazz::Page.new(@wiki,title)
      }
    end
  end
end

# def page(name,title,write_authorized=false)
#   page = {}
# 
#   # ロボット検索可能かどうか
#   page['searchable'] = attr(name,'searchable')
# 
#   page['do_auth'] = false
# 
#   page['rawdata'] = readdata(name,title)['data'].join("\n")
# 
#   #  page['rawdata'] = ''
#   #  data_file = Gyazz.datafile(name,title)
#   #  if File.exist?(data_file) then
#   #    page['rawdata'] = File.read(data_file)
#   #    if title == ALL_AUTH then
#   #      if !cookie_authorized?(name,ALL_AUTH) then
#   #        page['rawdata'] = randomize(page['rawdata'])
#   #        page['do_auth'] = true
#   #      end
#   #    elsif title == WRITE_AUTH then
#   #      if !cookie_authorized?(name,WRITE_AUTH) then
#   #        page['rawdata'] = randomize(page['rawdata'])
#   #        page['do_auth'] = true
#   #      end
#   #    end
#   #  end
# 
#   page['write_authorized'] = write_authorized
# 
#   page['name'] = name
#   page['title'] = title
#   page['related'] = related_pages(name,title) # この中でURL生成したりしてるのがよくない
# 
#   page
# 
#   # response["Access-Control-Allow-Origin"] = "*"
# end
