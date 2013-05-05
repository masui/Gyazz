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
          kw !~ /^[a-fA-F0-9]{32}/ then
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
          kw !~ /^[a-fA-F0-9]{32}/ then
        a << kw
      end
    end
    a
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class KeywordTest < Test::Unit::TestCase
    def test_1
      s = "[[abc]] [[def]] などはキーワード"
      keywords = s.keywords
      assert_equal keywords.length, 2
      assert keywords.member?('abc')
      assert keywords.member?('def')
    end

    def test_2
      s = "[[http://example.org/]] [[@masui]] などはキーワードにならない"
      keywords = s.keywords
      assert_equal keywords.length, 0
    end

    def test_3
      s = "[[E139.25.46.31N35.22.19.50Z17]]もキーワードにならない"
      keywords = s.keywords
      assert_equal keywords.length, 0
    end
  end
end

