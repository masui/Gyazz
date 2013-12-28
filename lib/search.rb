# -*- coding: utf-8 -*-

require 'asearch'

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
      @disptitle[id] = title + " " + Gyazz::Page.new(name,title).text.split(/\n/)[0]
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
