# -*- coding: utf-8 -*-
require File.expand_path 'wiki/rss', File.dirname(__FILE__)

module Gyazz
  class Wiki
    @@cached_wiki = {}
    @@orig_new = self.method(:new)
    def self.new(name)
      if @@cached_wiki[name]
        return @@cached_wiki[name]
      else
        @@cached_wiki[name] = @@orig_new.call(name)
      end
    end

    include Attr

    def initialize(name)
      @name = name
      Gyazz.id2title(id,@name) # nameとIDとの対応を登録

      @cached_pages = Set.new
    end
    attr_reader :name
    attr :cached_pages, true

    def dir
      dir = "#{Gyazz::FILEROOT}/#{id}"
      Dir.mkdir(dir) unless File.exist?(dir)
      dir
    end
    
    def id
      @name.md5
    end

    def allpages
      if !@initialized then
        @initialized = true
        Dir.open(dir).find_all { |file|
          file =~ /^[\da-f]{32}$/
        }.collect { |id|
          Gyazz.id2title(id)
        }.find_all { |title|
          title != ''
        }.collect { |title|
          Page.new(self,title)
        }
      else
        cached_pages.to_a
      end
    end

    def validpages # 中身が空でないもの
      allpages.find_all { |page|
        text = page.text
        text !~ /^\s*$/ && text != '(empty)' # これが遅い
      }
    end

    def disppages # タイトル先頭が「.」でないもの
      validpages.find_all { |page|
        page.title !~ /^\./
      }
    end

    def pages(query='',method = :modtime) # :accesstime ?
      pages = disppages.sort { |pagea,pageb|
        pageb.send(method) <=> pagea.send(method)
      }
      query == '' ? pages : pages.find_all { |page|
        query == '' || page.title.match(/#{query}/i) || page.text.match(/#{query}/i)
      }
    end

    

  end
end
