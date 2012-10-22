# -*- coding: utf-8 -*-
require 'test/unit'

$: << 'lib'
require 'contenttype'

class ContentTypeTest < Test::Unit::TestCase
  def test_1
    assert_equal contenttype('.exe'), 'application/octet-stream'
    assert_equal contenttype('.txt'), 'text/plain'
  end
end

