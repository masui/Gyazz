# -*- coding: utf-8 -*-

module Gyazz
  class Wiki
    include Attr

    def initialize(name)
      @name = name
      Gyazz.id2title(id,@name) # nameとIDとの対応を登録
    end
    attr_reader :name

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

    def validpages # 中身が空でないもの
      allpages.find_all { |page|
        page.text != ''
      }
    end

    def disppages # タイトル先頭が「.」でないもの
      validpages.find_all { |page|
        page.title !~ /^\./
      }
    end

    def pages(query='',method = :accesstime)
      disppages.sort { |pagea,pageb|
        pageb.send(method) <=> pagea.send(method)
      }.find_all { |page|
        query == '' || page.title.match(/#{query}/i) || page.text.match(/#{query}/i)
      }
    end

    def rss(root='http://Gyazz.com/')
      rss = RSS::Maker.make("2.0") do |rss|
        rss.channel.about = "#{root}/#{name}/rss.xml"
        rss.channel.title = "Gyazz - #{name}"
        rss.channel.description = "Gyazz - #{name}"
        rss.channel.link = "#{root}/#{name}"
        rss.channel.language = "ja"
        
        rss.items.do_sort = true
        rss.items.max_size = 15
        
        disppages[0...15].each { |page|
          i = rss.items.new_item
          i.title = page.title
          i.link = "#{root}/#{name}/#{page.title}"
          i.date = page.modtime
          i.description = (password_required? ? i.date.to_s : page.text)
        }
      end
      rss.to_s
    end

  end
end
