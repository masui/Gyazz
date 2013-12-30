# -*- coding: utf-8 -*-

module Gyazz
  class Page
    include Attr

    def initialize(wiki,title)
      @wiki = wiki
      if wiki.class == String
        @wiki = Wiki.new(wiki)
      end

      @title = title
      Gyazz.id2title(id,title) # titleとIDとの対応セット

      self['do_auth'] = 'false'
      self['write_authorized'] = 'true' # ***********

      #
      # 新規ページ作成時、大文字小文字を間違えたページが既に作られていないかチェック ... ここでやるべきか?
      # 候補ページを追加してJSONで返すといいのかも?
      # Page.new でやるべきかもしれない
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

    def curdata
      File.exist?(curfile) ? File.read(curfile) : ''
    end

    def datafile(version=0)
      files = [curfile] + backupfiles
      files[version.to_i] || files.last
    end

    def text(version=0)
      file = datafile(version)
      s = (File.exist?(file) ? File.read(file)  : '')
      s.sub(/\s+$/,'')
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
      olddata = curdata

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
        else
          File.open(curfile,"w"){ |f|
            f.print newdata
          }
          status = 'noconflict'
        end
      end

      # 各行のタイムスタンプ保存
      data.split(/\n/).each { |line|
        line.sub!(/^\s*/,'')
        line.sub!(/\s*$/,'')
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
          line.sub!(/^\s*/,'')
          line.sub!(/\s*$/,'')
          ts = self[timestampkey(line)]
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
      # backupids[0] ? backupids[0].to_time : File.mtime(curfile)
    end

    def accesstime
      access_history.last.to_s
    end

    def related_pages
      related_titles(self).collect { |title|
        Page.new(@wiki,title)
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
