require File.expand_path 'test_helper', File.dirname(__FILE__)

class ContentTypeTest < MiniTest::Unit::TestCase
  def test_1
    assert_equal contenttype('.exe'), 'application/octet-stream'
    assert_equal contenttype('.txt'), 'text/plain'
  end
end
