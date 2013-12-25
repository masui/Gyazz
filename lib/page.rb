# -*- coding: utf-8 -*-

module Gyazz
  class Page
    def initialize(wiki,title)
      @wiki = wiki
      if wiki.class == String
        @wiki = Wiki.new(wiki)
      end
      @title = title
      @timestamp = SDBM.open("#{backupdir}/timestamp",0644)
      @attr = {}
      @attr['do_auth'] = 'false'
      @attr['write_authorized'] = 'true'
    end
    attr :wiki
    attr :title
    attr :attr
    attr :timestamp, true

    def datafile(version=0)
      version = version.to_i
      curfile = "#{@wiki.topdir}/#{@title.md5}"
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

    def data(version=nil) # readdata() の置き換え
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

    def backupdir
      dir = "#{@wiki.topdir}/backups"
      Dir.mkdir(dir) unless File.exist?(dir)
      dir = "#{@wiki.topdir}/backups/#{@title.md5}"
      Dir.mkdir(dir) unless File.exist?(dir)
      dir
    end
    
    def backupfiles
      backups = []
      if File.exist?(backupdir) then
        Dir.open(backupdir).each { |f|
          backups << f if f =~ /^.{14}$/
        }
      end
      backups.sort{ |a,b|
        b <=> a
      }.collect { |f|
        "#{backupdir}/#{f}"
      }
    end

    def repimage
      db = SDBM.open("#{@wiki.topdir}/repimage")
      image = db[title]
      db.close
      image
    end
    
    def repimage=(image)
      db = SDBM.open("#{@wiki.topdir}/repimage")
      db[title] = image
      db.close
      image
    end
    
    def access_count
      access = SDBM.open("#{FILEROOT}/access",0644);
      key = "#{@wiki.name}(#{@wiki.name.md5})/#{title}(#{title.md5})"
      value = access[key].to_i
      access.close
      value
    end
    
    def access_count=(count)
      access = SDBM.open("#{FILEROOT}/access",0644);
      key = "#{@wiki.name.md5}(#{@wiki.name.md5})/#{title}(#{title.md5})"
      access[key] = count.to_s
      access.close
      count
    end

    def log_access_history()
      # アクセスされたときこれで登録する
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
