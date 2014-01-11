require 'fileutils'

module Gyazz
  def self.create_directories
    FileUtils.mkdir_p FILEROOT
    FileUtils.mkdir_p "#{FILEROOT}/upload"
    File.delete 'public/upload' if File.exists? 'public/upload'
    File.symlink "#{FILEROOT}/upload", 'public/upload'
  end
end

Gyazz::create_directories
