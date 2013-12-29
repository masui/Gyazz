module Gyazz
  module Attr
    def [](key)
      attr = SDBM.open("#{dir}/attr",0644)
      val = attr[key]
      attr.close
      val
    end
    
    def []=(key,val)
      attr = SDBM.open("#{dir}/attr",0644)
      attr[key] = val
      attr.close
      val
    end
  end
end
