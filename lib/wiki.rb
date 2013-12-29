# -*- coding: utf-8 -*-

module Gyazz
  class Wiki
    def initialize(name)
      @name = name
      Gyazz.id2title(id,@name) # nameとIDとの対応を登録
    end
    attr_reader :name

    def [](key)
      attr = SDBM.open("#{dir}/attr",0644)
      val = attr[key]
      attr.close
      val
    end

    def []=(key,val)
      attr = SDBM.open("#{dir}/attr",0644)
      attr[key] = val
      attr.close
      val
    end

    def dir
      dir = "#{FILEROOT}/#{id}"
      Dir.mkdir(dir) unless File.exist?(dir)
      dir
    end
    
    def id
      @name.md5
    end

    def allpages
      Dir.open(dir).find_all { |file|
        file =~ /^[\da-f]{32}$/
      }.collect { |id|
        Gyazz.id2title(id)
      }.find_all { |title|
        title != ''
      }.collect { |title|
        Page.new(self,title)
      }
    end

    def disppages
      # タイトル先頭が「.」のもの、空のものはリストしない
      allpages.find_all { |page|
        page.title !~ /^\./ && page.text != ''
      }
    end

    def titles
      disppages.collect { |page|
        page.title
      }
    end
    
    #    # ページのIDのリストを新しい順に
    #    def hotids
    #      pageids.sort { |a,b|
    #        pagea = Page.new(self,Gyazz.id2title(a))
    #        pageb = Page.new(self,Gyazz.id2title(b))
    #        pageb.modtime <=> pagea.modtime
    #      }
    #    end
    #    
    #    # ページのタイトルのリストを新しい順に
    #    def hottitles
    #      hotids.collect { |id|
    #        Gyazz.id2title(id)
    #      }
    #    end
    
    def pages(query='',method = :accesstime)
      disppages.sort { |pagea,pageb|
        pageb.send(method) <=> pagea.send(method)
      }.find_all { |page|
        query == '' || page.title.match(/#{query}/i) || page.text.match(/#{query}/i)
      }
    end
  end
end
