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
        text = page.text
        text != '' && text != '(empty)' # これが遅い
        #File.exist?(page.curfile)
      }
    end

    def disppages # タイトル先頭が「.」でないもの
      validpages.find_all { |page|
        page.title !~ /^\./
      }
    end

    def pages(query='',method = :accesstime)
      pages = disppages.sort { |pagea,pageb|
        pageb.send(method) <=> pagea.send(method)
      }
      query == '' ? pages : pages.find_all { |page|
        query == '' || page.title.match(/#{query}/i) || page.text.match(/#{query}/i)
      }
    end

  end
end
