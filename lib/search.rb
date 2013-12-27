# -*- coding: utf-8 -*-

require 'sdbm'
require 'asearch'

# nameという名前のGyazzサイトのページのIDのリスト取得
#def ids(name)
#  top = Gyazz.topdir(name)
#
#  pair = Pair.new("#{top}/pair")
#  titles = pair.keys
#  pair.close
#
#  @id2title = {}
#  titles.each { |title|
#    @id2title[Gyazz.md5(title)] = title
#  }
#
#  # ファイルの存在を確認
#  @ids = Dir.open(top).find_all { |file|
#    file =~ /^[\da-f]{32}$/ && @id2title[file].to_s != ''
#  }
#  
#  # 参照時間/更新時間を計算
#  @modtime = {}
#  @atime = {}
#  @ids.each { |id|
#    @modtime[id] = File.mtime("#{top}/#{id}")
#    @atime[id] = File.atime("#{top}/#{id}")
#  }
#  
#  @ids
#end
#
## nameという名前のGyazzサイトのページのIDのリストを新しい順に
#def hotids(name)
#  ids(name).sort { |a,b|
#    @modtime[b] <=> @modtime[a]
#  }
#end
#  
## nameという名前のGyazzサイトのページのタイトルのリストを新しい順に
#def hottitles(name)
#  hotids(name).collect { |id|
#    @id2title[id]
#  }
#end

def search(name,query='',namesort=false)
  @wiki = Gyazz::Wiki.new(name)

  @ids = @wiki.pageids

  @hotids =
    if namesort then
      @ids.sort { |a,b|
        Gyazz.id2title(b) <=> Gyazz.id2title(a)
      }
    elsif @wiki.attr['sortbydate'] then
      @wiki.pages.sort { |pagea,pageb|
        pageb.createtime <=> pagea.createtime
      }.collect { |page|
        page.id
      }
    else
      puts @wiki.pages
      @wiki.pages.sort { |pagea,pageb|
        pageb.accesstime <=> pagea.accesstime
      }.collect { |page|
        page.id
      }
    end

  # タイトル先頭が"."のものはリストしない
  @hotids = @hotids.find_all { |id|
    Gyazz.id2title(id) !~ /^\./
  }

  @q = query
  @matchids = @hotids
  if @q != '' then
    @matchids = @hotids.find_all { |id|
      title = Gyazz.id2title(id)
      content = Gyazz::Page.new(name,title).text
      title.match(/#{@q}/i) || content.match(/#{@q}/i)
    }
  end

  @pagetitle = (query == '' ? 'ページリスト' : "「#{query}」検索結果")

  # ページタイトルが日付だけだったりするページの場合は1行目を表示タイトルにする
  @disptitle = {}
  @hotids.each { |id|
    title = Gyazz.id2title(id)
    @disptitle[id] = title
    if title =~ /^[0-9]{14}$/ then
      file = "#{Gyazz.topdir(name)}/#{id}"
      if File.exist?(file) then
        @disptitle[id] = title + " " + File.read(file).split(/\n/)[0]
      end
    end
  }
end

# gyazz-ruby で使うためのもの? 意味がよくわからない
def list(name)
  hotids(name).collect { |id|
    title = Gyazz.id2title(id)
    [title, @modtime[id].to_i, "#{name}/#{title}", repimage(name,title)]
  }.to_json
end

## 似たページ名を探す
## "macruby", "Mac Ruby", "mac ruby" -> MacRuby
## "IPWebcam", "ip webcam", "IP WebCam" -> IP Webcam
def similar_page_titles(name, title)
  @ids = ids(name)

  titles = @ids.map do |id|
    s = Gyazz.id2title(id).dup
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
