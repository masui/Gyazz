# -*- coding: utf-8 -*-
require File.expand_path 'test_helper', File.dirname(__FILE__)

class AuthTest < MiniTest::Unit::TestCase
  def setup
    @wiki = Gyazz::Wiki.new('test_wiki')
  end

  def teardown
    system "/bin/rm -r -f #{@wiki.dir}"
  end

  def test_random
    page = Gyazz::Page.new(@wiki,'.完全認証')
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
    page.write(s)
    assert @wiki.auth_page_exist?
    assert page.is_all_auth_page?
    assert page.text.size == page.randomtext.size
    assert page.text != page.randomtext
    assert page.auth_cookie.length == 32
    assert page.authanswer == ' 4, A, F, jjjj'
  end

  def test_password
    page = Gyazz::Page.new(@wiki,'.password')
    page.write("user\npass\n")
    assert @wiki.password_required?
    assert @wiki.password_data[0] == 'user'
    assert @wiki.password_data[1] == 'pass'
  end
end
