require File.expand_path 'test_helper', File.dirname(__FILE__)

class TimeTest < MiniTest::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_1
    t = Time.now
    assert t.stamp == t.stamp.to_time.stamp
  end
end
