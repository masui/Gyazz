# -*- coding: utf-8 -*-
require File.expand_path 'test_helper', File.dirname(__FILE__)

class MD5Test < MiniTest::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_1
    s = 'abcdefg'
    assert s.md5 =~ /^[\da-f]{32}$/
  end
end
