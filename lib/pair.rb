class Pair
  require 'sdbm'
  DELIM = "\t"

  def initialize(dbmfile)
    @dbmfile = dbmfile
    @pairs = SDBM.open(dbmfile,0666) unless @pairs
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

