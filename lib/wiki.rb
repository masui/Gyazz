# -*- coding: utf-8 -*-

module Gyazz
  class Wiki
    def initialize(name)
      @name = name
      @id = name.md5
      Gyazz.id2title(@id,@name) # nameとIDとの対応を登録
      @attr = SDBM.open("#{dir}/attr",0644) unless @attr
    end
    attr :name
    attr :attr
    attr :id

    def dir
      dir = "#{FILEROOT}/#{@id}"
      Dir.mkdir(dir) unless File.exist?(dir)
      dir
    end
    
    def pageids
      Dir.open(dir).find_all { |file|
        title = Gyazz.id2title(file)
        # タイトル先頭が「.」のものはリストしない
        file =~ /^[\da-f]{32}$/ && title != '' && title !~ /^\./ && Page.new(self,title).curdata != ''
      }
    end

    def titles
      pageids.collect { |pageid|
        Gyazz.id2title(pageid)
      }
    end
    
    # ページのIDのリストを新しい順に
    def hotids
      pageids.sort { |a,b|
        pagea = Page.new(self,Gyazz.id2title(a))
        pageb = Page.new(self,Gyazz.id2title(b))
        pageb.modtime <=> pagea.modtime
        # @modtime[b] <=> @modtime[a]
      }
    end
    
    # ページのタイトルのリストを新しい順に
    def hottitles
      hotids.collect { |id|
        Gyazz.id2title(id)
      }
    end
    
    def pages
      hottitles.collect { |title|
        Page.new(self,title)
      }
    end
  end
end
