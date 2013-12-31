# -*- coding: utf-8 -*-
require 'digest/md5'

class String
  def md5
    Digest::MD5.new.hexdigest(self).to_s
  end
end

# md5値を元文字列に戻す
module Gyazz
  @@id2title = nil

  def self.id2title(id,title=nil)
    @@id2title = SDBM.open("#{Gyazz::FILEROOT}/id2title",0644) unless @@id2title
    if title then
      @@id2title[id] = title
    else
      title = @@id2title[id]
    end
    title.to_s
  end
end
