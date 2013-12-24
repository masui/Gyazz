# -*- coding: utf-8 -*-

require 'sdbm'
require 'asearch'

def titles(name)
  top = Gyazz.topdir(name)
  unless File.exist?(top) then
    Dir.mkdir(top)
  end

  pair = Pair.new("#{top}/pair")
  titles = pair.keys
  pair.close

  @id2title = {}
  titles.each { |title|
    @id2title[Gyazz.md5(title)] = title
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
  top = Gyazz.topdir(name)
  unless File.exist?(top) then
    Dir.mkdir(top)
  end

  pair = Pair.new("#{top}/pair")
  titles = pair.keys
  pair.close

  @id2title = {}
  titles.each { |title|
    @id2title[Gyazz.md5(title)] = title
  }

  ids = Dir.open(top).find_all { |file|
    file =~ /^[\da-f]{32}$/ && @id2title[file].to_s != ''
  }

  modtime = {}
  ids.each { |id|
    modtime[id] = File.mtime("#{top}/#{id}")
  }
  atime = {}
  ids.each { |id|
    atime[id] = File.atime("#{top}/#{id}")
  }

  @sortbydate = false
  if File.exist?("#{Gyazz.topdir(name)}/attr.dir") then
    attr = SDBM.open("#{Gyazz.topdir(name)}/attr",0644);
    @sortbydate = (attr['sortbydate'] == 'true' ? true : false)
    attr.close
  end

  hotids =
    if namesort then
      ids.sort { |a,b|
        @id2title[b] <=> @id2title[a]
      }
    elsif @sortbydate then
      @createtime = {}
      ids.each { |id|
        t = modtime[id].strftime('%Y%m%d%H%M%S')
        title = @id2title[id]
        if File.exist?(Gyazz.backupdir(name,title)) then
          Dir.open(Gyazz.backupdir(name,title)).each { |f|
            t = f if f =~ /^[0-9a-fA-F]{14}$/ && f < t
          }
        end
        @createtime[id] = t
      }
      ids.sort { |a,b|
        @createtime[b] <=> @createtime[a]
      }
    else
      ids.sort { |a,b|
      #modtime[b] <=> modtime[a]
      atime[b] <=> atime[a]
    }
    end

  # 先頭が"."のものはリストしない
  hotids = hotids.find_all { |id|
    @id2title[id] !~ /^\./
  }

  @q = query
  @matchids = hotids
  if @q != '' then
    @matchids = hotids.find_all { |id|
      title = @id2title[id]
      content = File.read("#{Gyazz.topdir(name)}/#{id}")
      title.match(/#{@q}/i) || content.match(/#{@q}/i)
    }
  end

  @urltop = topurl(name)
  @name = name
  @pagetitle = (query == '' ? 'ページリスト' : "「#{query}」検索結果")

  @disptitle = {}
  @id2title.each { |id,title|
    @disptitle[id] = title
    if title =~ /^[0-9]{14}$/ then
      file = "#{Gyazz.topdir(name)}/#{id}"
      if File.exist?(file) then
        @disptitle[id] = title + " " + File.read(file).split(/\n/)[0]
      end
    end
  }
end

def list(name)
  top = Gyazz.topdir(name)
  unless File.exist?(top) then
    Dir.mkdir(top)
  end

  pair = Pair.new("#{top}/pair")
  titles = pair.keys
  pair.close

  @id2title = {}
  titles.each { |title|
    @id2title[Gyazz.md5(title)] = title
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
  # アイコン
  @repimages = SDBM.open("#{Gyazz.topdir(name)}/repimage",0644)
  # JSON作成
  $KCODE = "u"
  "[\n" +
    @hotids.collect { |id|
    s = @id2title[id].dup
    ss = s.dup
    title = ""
    icon_url = ""
    while s.sub!(/^(.)/,'') do
      c = $1
      u = c.unpack("U")[0]
      title += (u < 0x80 && c != '"' ? c : sprintf("\\u%04x",u))
      icon_url = @repimages[title] ? @repimages[title] : ""
    end
    "  [\"#{ss.gsub(/"/,'\"')}\", #{@modtime[id].to_i}, \"#{name}/#{ss.gsub(/"/,'\"')}\", \"#{icon_url}\" ]"
  }.join(",\n") +
    "\n]\n"
end

## 似たページ名を探す
## "macruby", "Mac Ruby", "mac ruby" -> MacRuby
## "IPWebcam", "ip webcam", "IP WebCam" -> IP Webcam
def similar_page_titles(wiki_name, title)
  top = Gyazz.topdir wiki_name
  Dir.mkdir top unless File.exist? top

  pair = Pair.new "#{top}/pair"
  titles = pair.keys
  pair.close

  id2title = {}
  titles.each do |i|
    id2title[Gyazz.md5(i)] = i
  end

  ids = Dir.open(top).find_all { |file|
    file =~ /^[\da-f]{32}$/ && id2title[file].to_s != ''
  }

  titles = ids.map do |id|
    s = id2title[id].dup
    ss = s.dup
    title_ = ""
    while s.sub!(/^(.)/,'') do
      c = $1
      u = c.unpack("U")[0]
      title_ += (u < 0x80 && c != '"' ? c : sprintf("\\u%04x",u))
    end
    title_
  end

  pattern = Asearch.new title.strip
  similar_titles = []
  1.upto(2) do |level|
    titles.each do |i|
      if i != title and pattern.match(i, level)
        similar_titles << i.gsub(/"/,'\"')
      end
    end
    break unless similar_titles.empty?
  end
  similar_titles
end
