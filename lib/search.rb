# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'pair'
require 'sdbm'

def titles(name)
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

  modtime = {}
  ids.each { |id|
    modtime[id] = File.mtime("#{top}/#{id}")
  }

  hottitles = ids.sort { |a,b|
    modtime[b] <=> modtime[a]
  }.collect { |id|
    @id2title[id]
  }
end

def search(name,query='',namesort=false)
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

  modtime = {}
  ids.each { |id|
    modtime[id] = File.mtime("#{top}/#{id}")
  }

  hotids = 
    if namesort then
      ids.sort { |a,b|
        @id2title[b] <=> @id2title[a]
      }
    else
      ids.sort { |a,b|
        modtime[b] <=> modtime[a]
      }
    end

  @q = query
  @matchids = hotids
  if @q != '' then
    @matchids = hotids.find_all { |id|
      title = @id2title[id]
      content = File.read("#{topdir(name)}/#{id}")
      title.match(/#{@q}/i) || content.match(/#{@q}/i)
    }
  end

  repimage = SDBM.open("#{topdir(name)}/repimage",0644)
  @matchimages = @matchids.collect { |id|
    title = @id2title[id]
    if repimage[title] then
      @target_url = "#{URLROOT}/#{name}/#{title}"
      @target_title = title
      @imageurl = "http://gyazo.com/#{repimage[title]}.png"
      erb :icon
    else
      ''
    end
  }.join('')

  @urltop = topurl(name)
  @name = name
  @urlroot = URLROOT

  erb :search

end

def list(name)
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

  # JSON作成
  $KCODE = "u"
  "[\n" +
    @hotids.collect { |id|
    s = @id2title[id].dup
    ss = s.dup
    title = ""
    while s.sub!(/^(.)/,'') do
      c = $1
      u = c.unpack("U")[0]
      title += (u < 0x80 && c != '"' ? c : sprintf("\\u%04x",u))
    end
#    "  [\"#{title}\", #{@modtime[id].to_i}]"
    "  [\"#{ss.gsub(/"/,'\"')}\", #{@modtime[id].to_i}]"
  }.join(",\n") +
    "\n]\n"
end
