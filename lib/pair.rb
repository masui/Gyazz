class Pair
  require 'sdbm'
  DELIM = "\t"

  def initialize(dbmfile)
    @dbmfile = dbmfile
    @pairs = SDBM.open(dbmfile,0666)
  end

  def clear
    @pairs.each { |key,val|
      @pairs.delete(key)
    }
  end

  def str(s1,s2)
    [s1,s2].sort.join(DELIM)
  end

  def add(s1,s2)
    @pairs[str(s1,s2)] = ''
  end

  def delete(s1,s2)
    @pairs.delete(str(s1,s2))
  end

  def size
    @pairs.keys.length
  end

  def each(keyword = nil)
    if keyword then
      @pairs.each { |key,val|
        a = key.split(DELIM) rescue next
        if a[0] == keyword then
          yield a[1]
        elsif a[1] == keyword then
          yield a[0]
        end
      }
    else
      @pairs.each { |key,val|
        a = key.split(DELIM) rescue next
        yield a[0], a[1]
      }
    end
  end

  def collect(keyword)
    ret = []
    each(keyword){ |key|
      ret << key
    }
    ret
  end

  def keys
    v = {}
    each { |key1,key2|
      v[key1] = ''
      v[key2] = ''
    }
    v.keys
  end

  def close
    @pairs.close
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class PairTest < Test::Unit::TestCase
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
end

