# -*- coding: utf-8 -*-
#
# ページやサイトの属性記録に page[key] = val, wiki[key] = val などを利用できるようにするモジュール
#
module Gyazz
  module Attr
    def [](key)
      SDBM.open("#{dir}/attr",0644){ |attr|
        attr[key]
      }
    end
    
    def []=(key,val)
      SDBM.open("#{dir}/attr",0644){ |attr|
        attr[key] = val
      }
    end
  end
end
