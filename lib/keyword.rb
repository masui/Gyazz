# -*- coding: utf-8 -*-
class String
  def keywords # [[...]] のキーワードを配列にして返す
    s = self.dup
    a = []
    while s.sub!(/\[\[\[[^\]\n\r]+\]\]\]/,'') do
    end
    while s.sub!(/\[\[([^\[\n\r ]+\/) [^\]]+\]\]/,'') do
      kw = $1
      if kw !~ /^http/ && 
          kw !~ /^javascript:/ && 
          kw !~ /pdf / && 
          kw !~ /^@/ && 
          kw !~ /::/ && 
          kw !~ /^([EWNSZ][1-9][0-9\.]*)+$/ &&
          kw !~ /\.icon((\*|x|×)[\d\.]*)?$/i &&
          kw !~ /^[a-fA-F0-9]{32}/ then
        kw.sub!(/\.(png|icon|gif|jpe?g)((\*|x|×)[\d\.]*)?$/i,'')
        a << kw
      end
    end
    while s.sub!(/\[\[([^\[\n\r]+)\]\]/,'') do
      kw = $1
      if kw !~ /^http/ && 
          kw !~ /^javascript:/ && 
          kw !~ /pdf / && 
          kw !~ /^@/ && 
          kw !~ /::/ && 
          kw !~ /^([EWNSZ][1-9][0-9\.]*)+$/ &&
          kw !~ /\.icon((\*|x|×)[\d\.]*)?$/i &&
          kw !~ /^[a-fA-F0-9]{32}/ then
        kw.sub!(/\.(png|icon|gif|jpe?g)((\*|x|×)[\d\.]*)?$/i,'')
        a << kw
      end
    end
    a
  end
end
