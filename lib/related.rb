# -*- coding: utf-8 -*-

def page_weight(name,title)
  pair = Pair.new("#{Gyazz.topdir(name)}/pair")

  pagekeywords = []
  filename = Gyazz.datafile(name,title,0)
  if File.exist?(filename) then
    pagekeywords = File.read(filename).keywords
    # File.utime(Time.now,Time.now,filename) # 何故こうしてたのか?
  end

  #
  # http://pitecan.com/~masui/Wiki/リンク重要度計算
  #
  linkcount = {}
  pair.each { |key1,key2|
    linkcount[key1] = 0.0 unless linkcount[key1]
    linkcount[key2] = 0.0 unless linkcount[key2]
    linkcount[key1] += 1.0
    linkcount[key2] += 1.0
  }

  linkcount2 = {}
  pair.each { |key1,key2|
    linkcount2[key1] = 0.0 unless linkcount2[key1]
    linkcount2[key2] = 0.0 unless linkcount2[key2]
    linkcount2[key1] += linkcount[key2]
    linkcount2[key2] += linkcount[key1]
  }

  weight = {}
  pair.each(title) { |key|
    next if key =~ /^@/ # 苦しい。pairをクリアしなければ
    next if key =~ /::/ # 苦しい。pairをクリアしなければ
    weight[key] = linkcount[key]
  }
  newweight = {}
  pair.each { |key1,key2|
    if weight[key1] && !weight[key2] then
      newweight[key2] = 0.0 unless newweight[key2]
      newweight[key2] += linkcount[key2] / linkcount2[key1]
    end
    if weight[key2] && !weight[key1] then
      newweight[key1] = 0.0 unless newweight[key1]
      newweight[key1] += linkcount[key1] / linkcount2[key2]
    end
  }
  newweight.each { |key,val|
    weight[key] = val
  }
  weight.delete(title)
  pair.close
  weight
end

def related(name,title)
  h = page_weight(name,title)
  h.keys.sort { |a,b|
    h[b] <=> h[a]
  }
end

def related_pages(name,title)
  top = Gyazz.topdir(name)
  related(name,title).collect{ |t|
    target = {}
    target['url'] = "#{app_root}/#{name}/#{URI.encode(t)}"
    if t =~ /^[0-9]{14}/ then
      file = "#{Gyazz.topdir(name)}/#{Gyazz.md5(t)}"
      t = File.read(file).split(/\n/)[0]
    end
    target['text'] = t
    target['title'] = t.sub(/^\d+\/\d+\/\d+\s+\d+:\d+:\d+\s+/,'').sub(/\[\[http\S+\s+(.*)\]\]/){ $1 }
    target['title'].sub!(/^[0-9a-f]{10}-/,'') # アップロードデータ管理用のハッシュを名前から除く
    imgeurl = nil
    image = repimage(name,t)
    if image.to_s != ''
      if image =~ /https?:\/\/.+\.(png|jpe?g|gif)/i
        target['imageurl'] = image
      else
        target['imageurl'] = "http://gyazo.com/#{image}.png"
      end
    end
    target
  }
end

if $0 == __FILE__ then
#  puts related_html("増井研","合宿")
  puts related_html("増井研","ブックマークレット")

  page_weight("増井研","合宿").collect { |title,val|
    puts "#{title}\t#{val}"
  }
end
