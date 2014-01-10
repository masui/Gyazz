# -*- coding: utf-8 -*-
require File.expand_path 'test_helper', File.dirname(__FILE__)

class MD5Test < MiniTest::Test
  def setup
    @wiki = Gyazz::Wiki.new('test_wiki')
  end

  def teardown
    system "/bin/rm -r -f #{@wiki.dir}"
  end

  def test_1
    s = 'abcdefg'
    assert s.md5 =~ /^[\da-f]{32}$/
  end

  def test_2
    assert Gyazz.id2title(@wiki.name.md5) == @wiki.name
  end
end
