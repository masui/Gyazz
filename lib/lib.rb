require 'config'
require 'digest/md5'

def md5(s)
   Digest::MD5.new.hexdigest(s).to_s
end

def name_id(name)
  md5(name)
end

def title_id(title)
  md5(title)
end

def topdir(name)
  "#{FILEROOT}/#{name_id(name)}"
end

def datafile(name,title)
  "#{FILEROOT}/#{name_id(name)}/#{title_id(title)}"
end


