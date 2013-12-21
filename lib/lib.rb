# -*- coding: utf-8 -*-
require 'digest/md5'

module Gyazz

  def self.topdir(name)
    "#{FILEROOT}/#{md5(name)}"
  end

  def self.md5(s)
    Digest::MD5.new.hexdigest(s.to_s).to_s
  end


  def self.backupdir(name,title=nil)
    return "#{topdir(name)}/backups" unless title
    return "#{topdir(name)}/backups/#{md5(title)}"
  end

  def self.newbackupfile(name,title)
    "#{backupdir(name,title)}/#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  def self.backupfiles(name,title)
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

  def self.datafile(name,title,version=0)
    version = version.to_i
    curfile = "#{Gyazz.topdir(name)}/#{md5(title)}"
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

end
