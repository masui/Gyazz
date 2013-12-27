# -*- coding: utf-8 -*-
# -*- coding: utf-8 -*-

module Gyazz
  @@id2title = nil

  # ここにあるのは変だろうか
  def self.id2title(id,title=nil)
    @@id2title = SDBM.open("#{FILEROOT}/id2title",0644) unless @@id2title
    if title then
      @@id2title[id] = title
    else
      title = @@id2title[id]
    end
    title.to_s
  end

  class Wiki
    def initialize(name)
      @name = name
      puts name
      @id = name.md5
      Gyazz.id2title(@id,@name) # nameとIDとの対応セット
      @attr = SDBM.open("#{dir}/attr",0644) # 以前backupdirだった
    end
    attr :name
    attr :attr, true

    def dir
      dir = "#{FILEROOT}/#{@id}"
      Dir.mkdir(dir) unless File.exist?(dir)
      dir
    end
    
    def pageids
      pair = Pair.new("#{dir}/pair")
      titles = pair.keys
      pair.close
      
      # ファイルの存在を確認
      ids = Dir.open(dir).find_all { |file|
        title = Gyazz.id2title(file)
        file =~ /^[\da-f]{32}$/ && 
        title != '' &&
        Page.new(self,title).curdata != ''
      }
      
      #      # 参照時間/更新時間を計算
      #      @modtime = {}
      #      ids.each { |id|
      #        @modtime[id] = File.mtime("#{dir}/#{id}")
      #      }
      
      ids
    end

    def titles
      pageids.collect { |pageid|
        Gyazz.id2title(pageid)
      }
    end
    
    # ページのIDのリストを新しい順に
    def hotids
      pageids.sort { |a,b|
        pagea = Gyazz::Page.new(self,Gyazz.id2title(a))
        pageb = Gyazz::Page.new(self,Gyazz.id2title(b))
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
