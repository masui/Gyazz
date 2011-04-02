# -*- coding: utf-8 -*-
class String
  def keywords # [[...]] のキーワードを配列にして返す
    s = self.dup
    a = []
    while s.sub!(/\[\[\[[^\]\n\r]+\]\]\]/,'') do
    end
    while s.sub!(/\[\[([^\[\n\r ]+\/) [^\]]+\]\]/,'') do
      kw = $1
      if kw !~ /^http/ && kw !~ /pdf / && kw !~ /^@/ && kw !~ /::/ && kw !~ /^[a-fA-F0-9]{32}/ then
        a << kw
      end
    end
    while s.sub!(/\[\[([^\[\n\r]+)\]\]/,'') do
      kw = $1
      if kw !~ /^http/ && kw !~ /pdf / && kw !~ /^@/ && kw !~ /::/ && kw !~ /^[a-fA-F0-9]{32}/ then
        a << kw
      end
    end
    a
  end
end
