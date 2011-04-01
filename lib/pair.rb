class Pair
  require 'sdbm'
  DELIM = "\t"

  def initialize(dbmfile)
    @dbmfile = dbmfile
    @pairs = SDBM.open(dbmfile,0666)
  end

  def clear
#    @pairs.close
#    begin
#      File.unlink "#{@dbmfile}.pag"
#      File.unlink "#{@dbmfile}.dir"
#      File.unlink "#{@dbmfile}.db"
#    rescue
#    end
#    @pairs = SDBM.open(@dbmfile,0666)
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

  def each(keyword = nil)
    if keyword then
      @pairs.each { |key,val|
        a = key.split(DELIM)
        if a[0] == keyword then
          yield a[1]
        elsif a[1] == keyword then
          yield a[0]
        end
      }
    else
      @pairs.each { |key,val|
        a = key.split(DELIM)
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
end

if __FILE__ == $0 then
  pair = Pair.new('testdbm')
  pair.clear
  pair.add('a','b')
  pair.add('aho','baka')
  pair.add('baka','aho')
  pair.add('a','bcd')
  pair.delete('aho','baka')
  pair.each { |s1,s2|
    puts s1
    puts s2
    puts "-----"
  }
  puts "================"
  pair.each('a') { |s|
    puts s
    puts "-----"
  }
  puts pair.collect('a').join('---')
  puts "================"
  puts pair.keys.join('-')
end
