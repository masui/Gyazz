# -*- coding: utf-8 -*-
require File.expand_path 'test_helper', File.dirname(__FILE__)

class AuthTest < MiniTest::Unit::TestCase
  def setup
    @wiki = Gyazz::Wiki.new('test_wiki')
    @page = Gyazz::Page.new(@wiki,'.完全認証')
  end

  def teardown
    system "/bin/rm -r -f #{@wiki.dir}"
  end

  def test_random
    s = <<EOF
[[gyazo.png]]
 A
 B
 C
 D
 E
[[gyazo2.png]]
 F
 G
2+3=
 4
 5
 6
 7
 8
aaaa
bbbbb
 jjjj
EOF
    @page.write(s)
    assert @page.text.size == @page.randomtext.size
    assert @page.text != @page.randomtext
  end
end
