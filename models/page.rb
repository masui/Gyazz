# -*- coding: utf-8 -*-
require File.expand_path 'page/related', File.dirname(__FILE__)
require File.expand_path 'page/suggest', File.dirname(__FILE__)
require File.expand_path 'page/visualize', File.dirname(__FILE__)

module Gyazz
  class Page
    @@text = {}
    @@access = {}

    include Attr

    def initialize(wiki,title)
      @wiki = wiki
      @wiki = Wiki.new(wiki) if wiki.class == String

      @wiki.cached_pages.add(self)

      @title = title
      Gyazz.id2title(id,title) # titleとIDとの対応セット
    end
    attr_reader :wiki, :title

    def dir
      dir = "#{@wiki.dir}/#{id}"
      Dir.mkdir(dir) unless File.exist?(dir)
      dir
    end

    def titlestr
      if title =~ /^[0-9]{14}$/ then 
        newtitle = ''
        text.split(/\n/).each { |line|
          if line !~ /http.*(png|jpe?g|gif)/i then
            newtitle = line
            break
          end
        }
        while newtitle =~ /^(.*)(\[\[([^\n\r]+)\]\])(.*)$/ do
          pre = $1
          tag = $3
          post = $4
          a = tag.split(/ /)
          if a[0] =~ /^http/ then
            if a[1] =~ /^http/ then
              newtitle = "#{pre}<<<#{tag}>>>#{post}"
            else
              a.shift
              newtitle = pre + a.join(' ') + post
            end
          else
            newtitle = pre + tag + post
          end
        end
        newtitle.gsub(/<<</,'[[').gsub(/>>>/,']]')
      else
        title
      end
    end

    def id
      @title.md5
    end
    
    def curfile # 現在編集中のファイル
      "#{dir}/curfile"
    end

    def datafile(version=0)
      files[version.to_i] || files.last
    end

    def text(version=0)
      ind = wiki.name + title
      cachedtext = @@text[ind]
      if version == 0 && cachedtext then
        cachedtext
      else
        file = datafile(version)
        s = (File.exist?(file) ? File.read(file)  : '')
        s.sub!(/\s+\Z/,'')
        @@text[ind] = s if version == 0
        s
      end
    end

    def exist?
      text != '' && text != '(empty)'
    end

    def timestampkey(line)
      "TimeStamp-#{line}"
    end
    
    def write(data,browser_md5=nil)
      # ブラウザからの要求のときはbrowser_md5に値がセットされる
      # gyazz-ruby のAPIや強制書込みの場合はbrowser_md5はセットされない
  
      newdata = data.gsub(/\n+/,"\n").sub(/\n+\Z/,'')+"\n" # newdata: 新規書込みデータ
      olddata = text.gsub(/\n+/,"\n").sub(/\n+\Z/,'')+"\n" # \Z は文字列の最後
      @@text[wiki.name+title] = newdata

      # 最新データをバックアップ
      if olddata != "" && olddata != newdata then
        File.open("#{dir}/#{modtime.stamp}",'w'){ |f|
          f.print(olddata)
        }
      end

      # 書込みコンフリクトを調べる
      #
      if olddata.md5 == browser_md5 || olddata == '' || browser_md5.nil? then
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
          system "patch -f #{curfile} < #{patchfile}" #### -f added
          File.delete newfile, patchfile
          status = 'conflict'

          # @@text[wiki.name+title] = nil
          @@text[wiki.name+title] = File.read(curfile).sub!(/\s+\Z/,'')
        else
          File.open(curfile,"w"){ |f|
            f.print newdata
          }
          status = 'noconflict - no oldfile'
          # status = 'noconflict'
        end
      end

      # 各行のタイムスタンプ保存
      data.split(/\n/).each { |line|
        line.strip!
        self[timestampkey(line)] = Time.now.stamp unless self[timestampkey(line)]
      }

      # リンク情報更新
      pair = Pair.new("#{@wiki.dir}/pair")
      olddata.keywords.each { |keyword|
        pair.delete(title,keyword)
      }
      newdata.keywords.each { |keyword|
        pair.add(title,keyword)
      }
      pair.close

      # 代表画像
      firstline = data.split(/\n/)[0]
      if firstline =~ /gyazo.com\/(\w{32})\.png/i then
        self['repimage'] = $1
      elsif firstline =~ /(https?:\/\/\S+)\.(png|jpe?g|gif)/i
        self['repimage'] = "#{$1}.#{$2}"
      else
        self['repimage'] = ''
      end
      
      status # 'conflict' or 'noconflict'
    end

    def data(version=nil) # page.erbに渡すための情報を付加
      ret = {}
      ret['data'] = text(version).gsub(/\n+/,"\n").sub(/\n+\Z/,'').split(/\n/)
      if version.to_i >= 0 then
        datafile(version) =~ /\/(\d{14})$/
        ret['date'] = (version == 0 ? modtime.stamp : $1 ? $1 : '')
        ret['age'] = ret['data'].collect { |line|
          ts = self[timestampkey(line.strip)]
          t = (ts ? ts.to_time : Time.now)
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
      backupids.collect { |backupid|
        "#{dir}/#{backupid}"
      }
    end

    def files
      [curfile] + backupfiles
    end

    def __accessfile
      "#{dir}/access"
    end

    def record_access_history # ページへのアクセス時刻を記録
      File.open(__accessfile,"a"){ |f|
        f.puts Time.now.stamp
      }
      @@access[wiki.name+title] = Time.now.stamp
    end

    def access_history
      File.exist?(__accessfile) ? File.read(__accessfile).split : []
    end

    def modtime
      File.exist?(curfile)? File.mtime(curfile) : Time.now
    end
    
    def modify_history
      backupids.reverse.push(modtime.stamp)
    end

    def createtime
      modify_history[0].to_time
    end

    def accesstime
      # File.exist?(curfile) ? File.atime(curfile) : Time.now
      ind = wiki.name+title
      atime = @@access[ind]
      if !atime
        t = access_history.last
        atime = @@access[ind] = (t ? t.to_time : "20000101000000".to_time).stamp
      end
      atime
    end
  end
end
