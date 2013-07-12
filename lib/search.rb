# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'pair'
require 'sdbm'
require 'history'
require 'asearch'

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
  atime = {}
  ids.each { |id|
    atime[id] = File.atime("#{top}/#{id}")
  }

  @sortbydate = false
  if File.exist?("#{topdir(name)}/attr.dir") then
    attr = SDBM.open("#{topdir(name)}/attr",0644);
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
        if File.exist?(backupdir(name,title)) then
          Dir.open(backupdir(name,title)).each { |f|
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
      content = File.read("#{topdir(name)}/#{id}")
      title.match(/#{@q}/i) || content.match(/#{@q}/i)
    }
  end

  repimage = SDBM.open("#{topdir(name)}/repimage",0644)
  @matchimages = @matchids.collect { |id|
    title = @id2title[id]
    if repimage[title] then
      @target_url = "#{app_root}/#{name}/#{title}"
      @target_title = title
      if repimage[t] =~ /https?:\/\/.+\.(png|jpe?g|gif)/i
        @imageurl = repimage[t]
      else
        @imageurl = "http://gyazo.com/#{repimage[t]}.png"
      end
      erb :icon
    else
      ''
    end
  }.join('')

  @urltop = topurl(name)
  @name = name
  @urlroot = app_root
  @pagetitle = (query == '' ? 'ページリスト' : "「#{query}」検索結果")

  @disptitle = {}
  @id2title.each { |id,title|
    @disptitle[id] = title
    if title =~ /^[0-9]{14}$/ then
      file = "#{topdir(name)}/#{id}"
      if File.exist?(file) then
        @disptitle[id] = title + " " + File.read(file).split(/\n/)[0]
      end
    end
  }

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
    "  [\"#{ss.gsub(/"/,'\"')}\", #{@modtime[id].to_i}, \"#{name}/#{ss.gsub(/"/,'\"')}\"]"
 }.join(",\n") +
    "\n]\n"
end

## 似たページ名を探す
## "macruby", "Mac Ruby", "mac ruby" -> MacRuby
## "IPWebcam", "ip webcam", "IP WebCam" -> IP Webcam
def similar_page_titles(wiki_name, title)
  top = topdir wiki_name
  Dir.mkdir top unless File.exist? top

  pair = Pair.new "#{top}/pair"
  titles = pair.keys
  pair.close

  id2title = {}
  titles.each do |i|
    id2title[md5(i)] = i
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
