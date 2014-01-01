# -*- coding: utf-8 -*-

module Gyazz
  class Page
    @@text = {}

    include Attr

    def initialize(wiki,title)
      @wiki = wiki
      @wiki = Wiki.new(wiki) if wiki.class == String

      @title = title
      Gyazz.id2title(id,title) # titleとIDとの対応セット

      #
      # 新規ページ作成時、大文字小文字を間違えたページが既に作られていないかチェック *******
      #
      # こんな感じのコードを入れる
      #  if !data or data.strip.empty? or data.strip == "(empty)"
      #    similar_titles = similar_page_titles(name, title)
      #    unless similar_titles.empty?
      #      suggest_title = similar_titles.sort{|a,b|
      #        readdata(name, b)['data'].join("\n").size <=> readdata(name, a)['data'].join("\n").size  # 一番大きいページをサジェスト
      #      }.first
      #      data = "\n-> [[#{suggest_title}]]" if suggest_title
      #    end
      #  end
    end
    attr_reader :wiki, :title

    def dir
      dir = "#{@wiki.dir}/#{id}"
      Dir.mkdir(dir) unless File.exist?(dir)
      dir
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
      if version == 0 && @@text[wiki.name+title] then
        return @@text[wiki.name+title]
      else
        file = datafile(version)
        s = (File.exist?(file) ? File.read(file)  : '')
        s.sub!(/\s+$/,'')
        @@text[wiki.name+title] = s if version == 0
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
  
      newdata = data.sub(/\n+$/,'')+"\n"      # newdata: 新規書込みデータ
      olddata = text
      @@text[wiki.name+title] = newdata

      # 最新データをバックアップ
      if olddata != "" && olddata != newdata then
        File.open("#{dir}/#{Time.now.stamp}",'w'){ |f|
          f.print(olddata)
        }
      end

      # 書込みコンフリクトを調べる
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
          system "patch #{curfile} < #{patchfile}"
          File.delete newfile, patchfile
          status = 'conflict'
          @@text[wiki.name+title] = nil
        else
          File.open(curfile,"w"){ |f|
            f.print newdata
          }
          status = 'noconflict'
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
      ret['data'] = text(version).sub(/\n+$/,'').split(/\n/)
      if version.to_i > 0 then
        datafile(version) =~ /\/(\d{14})$/
        ret['date'] = $1
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
      File.exist?(curfile) ? File.atime(curfile) : Time.now
    end
  end
end
