# -*- coding: utf-8 -*-
require File.expand_path 'test_helper', File.dirname(__FILE__)

class PageTest < MiniTest::Test
  def setup
    @wiki = Gyazz::Wiki.new("wikiname")
    @page = Gyazz::Page.new(@wiki, "pagename")
  end

  def teardown
  end

  def test_1
    # wiki = Gyazz::Wiki.new('test')
    # page = Gyazz::Page
  end

  def test_new
    assert_instance_of Gyazz::Page, Gyazz::Page.new(@wiki, "pagename")
    assert_same @page, Gyazz::Page.new(@wiki, "pagename")
    assert_instance_of Gyazz::Wiki, @page.wiki
    assert_equal "pagename", @page.title
  end
end
