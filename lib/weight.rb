# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'pair'
require 'keyword'

def _weight(name,title)
  pair = Pair.new("#{topdir(name)}/pair")

  pagekeywords = []
  filename = datafile(name,title)
  if File.exist?(filename) then
    pagekeywords = File.read(filename).keywords
    File.utime(Time.now,Time.now,filename)
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
  weight
end




if $0 == __FILE__ then
  weight("増井研","合宿").collect { |title,val|
    puts "#{title}\t#{val}"
  }
end

