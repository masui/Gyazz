# -*- coding: utf-8 -*-

require 'asearch'

def search(wiki,query='',namesort=false)
  # @wiki = Gyazz::Wiki.new(name)

  func = (namesort ? :title : wiki['sortbydate'] ? :createtime : :accesstime)

  # @pagetitle = (query == '' ? 'ページリスト' : "「#{query}」検索結果")

  wiki.pages.sort { |pagea,pageb|
    pageb.send(func) <=> pagea.send(func)
  }.find_all { |page|
    query == '' ||
    page.title.match(/#{query}/i) || page.text.match(/#{query}/i)
  }
    
  # @q = query

  #  @matchids = @hotids
  #  if @q != '' then
  #    @matchids = @hotids.find_all { |id|
  #      title = Gyazz.id2title(id)
  #      content = Gyazz::Page.new(name,title).text
  #      title.match(/#{@q}/i) || content.match(/#{@q}/i)
  #    }
  #  end


  #  # ページタイトルが日付だけだったりするページの場合は1行目を表示タイトルにする
  #  @disptitle = {}
  #  @hotids.each { |id|
  #    title = Gyazz.id2title(id)
  #    @disptitle[id] = title
  #    if title =~ /^[0-9]{14}$/ then
  #      @disptitle[id] = title + " " + Gyazz::Page.new(name,title).text.split(/\n/)[0]
  #    end
  #  }
end

# gyazz-ruby で使うためのもの? 意味がよくわからない
#def list(name)
#  Gyazz::Wiki.new(name).hottitles.collect { |title|
#    page = Gyazz::Page.new(name,title)
#    [title, page.modtime.to_i, "#{name}/#{title}", page.repimage]
#  }.to_json
#end

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
