# -*- coding: utf-8 -*-
require 'config'
require 'digest/md5'

def app_root()
  "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{env['SCRIPT_NAME']}"
end

def sanitize(s)
  s.gsub(/&/,'&amp;').gsub(/</,'&lt;')
end

def md5(s)
   Digest::MD5.new.hexdigest(s.to_s).to_s
end

def topdir(name)
  "#{FILEROOT}/#{md5(name)}"
end

def topurl(name)
  "#{app_root}/#{name}"
end

def backupdir(name,title=nil)
  if title then
    "#{FILEROOT}/#{md5(name)}/backups/#{md5(title)}"
  else
    "#{FILEROOT}/#{md5(name)}/backups"
  end
end

def newbackupfile(name,title)
  "#{backupdir(name,title)}/#{Time.now.strftime('%Y%m%d%H%M%S')}"
end

def backupfiles(name,title)
  backups = []
  if File.exist?(backupdir(name,title)) then
    Dir.open(backupdir(name,title)).each { |f|
      backups << f if f =~ /^.{14}$/
    }
  end
  backups.sort{ |a,b|
    b <=> a
  }.collect { |f|
    "#{backupdir(name,title)}/#{f}"
  }
end

def datafile(name,title,version=0)
  version = version.to_i
  curfile = "#{topdir(name)}/#{md5(title)}"
  if version == 0 then
    curfile
  else
    files = [curfile]
    files += backupfiles(name,title)
    if version >= files.length then
      version = files.length-1
    end
    files[version]
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class LibTest < Test::Unit::TestCase
    def test_1
      assert_equal sanitize('<ab>'), '&lt;ab>'
      assert_equal sanitize('&&'), '&amp;&amp;'
    end
  end
end


#if $0 == __FILE__ then
#  puts datafile('増井研','合宿')
#  puts datafile('増井研','合宿',0)
#  puts datafile('増井研','合宿',1)
#  puts datafile('増井研','合宿',2)
#  puts datafile('増井研','合宿',3)
#  puts datafile('増井研','合宿',10)
#  puts datafile('増井研','合宿',20)
#  puts datafile('増井研','合宿',30)
#end

