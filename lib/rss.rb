# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'pair'
require 'readdata'
require 'auth'
require 'rss/maker'

def rss(name)
  top = topdir(name)
  unless File.exist?(top) then
    Dir.mkdir(top)
  end

  pair = Pair.new("#{top}/pair")
  titles = pair.keys
  pair.close

  @id2title = {}
  titles.each { |title|
    @id2title[md5(title)] = title
  }

  ids = Dir.open(top).find_all { |file|
    file =~ /^[\da-f]{32}$/ && @id2title[file].to_s != ''
  }

  @modtime = {}
  ids.each { |id|
    @modtime[id] = File.mtime("#{top}/#{id}")
  }

  @hotids = ids.sort { |a,b|
    @modtime[b] <=> @modtime[a]
  }

  rss = RSS::Maker.make("2.0") do |rss|
    rss.channel.about = "http://Gyazz.com/#{name}/rss.xml"
    rss.channel.title = "Gyazz - #{name}"
    rss.channel.description = "Gyazz - #{name}"
    rss.channel.link = "http://Gyazz.com/#{name}"
    rss.channel.language = "ja"
  
    rss.items.do_sort = true
    rss.items.max_size = 15

    @hotids[0...15].each { |id|
      i= rss.items.new_item
      title = @id2title[id]
      i.title = title
      i.link = "http://Gyazz.com/#{name}/#{title}"
      i.description = (password_required?(name) ? '' : readdata(name,title,0))
      # i.description = readdata(name,title,0)
      i.date = @modtime[id]
    }
  end

  rss.to_s
end

if $0 == __FILE__ then
  puts rss('masui')
end
