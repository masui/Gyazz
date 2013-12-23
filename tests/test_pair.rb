require File.expand_path 'test_helper', File.dirname(__FILE__)

class PairTest < MiniTest::Unit::TestCase
  def setup
    @pair = Pair.new("/tmp/testpair")
  end

  def teardown
    File.delete "/tmp/testpair.pag"
    File.delete "/tmp/testpair.dir"
  end

  def test_1
    @pair.add('a','b')
    assert @pair.keys.length == 2
    assert @pair.size == 1
    @pair.add('a','b')
    assert @pair.keys.length == 2
    assert @pair.size == 1
    @pair.add('b','a')
    assert @pair.keys.length == 2
    assert @pair.size == 1
    @pair.add('b','c')
    assert @pair.keys.length == 3
    assert @pair.size == 2
    assert @pair.collect('b').length == 2
    @pair.delete('b','c')
    assert @pair.keys.length == 2
    assert @pair.size == 1
    @pair.add('b','c')
    assert @pair.keys.length == 3
    assert @pair.size == 2
    @pair.delete('c','b')
    assert @pair.keys.length == 2
    assert @pair.size == 1
    @pair.add('x','y')
    assert @pair.keys.length == 4
    assert @pair.size == 2
  end

  def test_2
    @pair.add('a','b')
    assert @pair.keys.length == 2
    assert @pair.size == 1
    @pair.clear
    assert @pair.keys.length == 0
    assert @pair.size == 0
  end
end