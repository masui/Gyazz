# -*- coding: utf-8 -*-
#
# ページやサイトの属性記録に page[key] = val, wiki[key] = val などを利用できるようにするモジュール
#
module Gyazz
  module Attr
    def [](key)
      #      attr = SDBM.open("#{dir}/attr",0644)
      #      val = attr[key]
      #      attr.close
      #      val
      SDBM.open("#{dir}/attr",0644){ |attr|
        attr[key]
      }
    end
    
    def []=(key,val)
      SDBM.open("#{dir}/attr",0644){ |attr|
        attr[key] = val
      }
      #      attr = SDBM.open("#{dir}/attr",0644)
      #      attr[key] = val
      #      attr.close
      #      val
    end
  end
end
