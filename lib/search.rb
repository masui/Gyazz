# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'pair'

def search(name,query='')
  top = topdir(name)
  unless File.exist?(top) then
    Dir.mkdir(top)
  end

  pair = Pair.new("#{top}/pair")
  titles = pair.keys

  @id2title = {}
  titles.each { |title|
    @id2title[md5(title)] = title
  }

  ids = Dir.open(top).find_all { |file|
    file =~ /^[\da-f]{32}$/ && @id2title[file].to_s != ''
  }

  modtime = {}
  ids.each { |id|
    modtime[id] = File.mtime("#{top}/#{id}")
  }

  hotids = ids.sort { |a,b|
    modtime[b] <=> modtime[a]
  }

  @q = query
  @matchids = hotids
  if @q != '' then
    @matchids = hotids.find_all { |id|
      title = @id2title[id]
      content = File.read("#{topdir(name)}/#{id}")
      title.match(/#{@q}/i) || content.match(/#{@q}/i)
    }
  end

  @urltop = topurl(name)
  @name = name
  @urlroot = URLROOT

  erb :list

end

