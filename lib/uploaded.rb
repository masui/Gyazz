# -*- coding: utf-8 -*-

require 'config'
require 'lib'
require 'sdbm'

def uploaded_html
  gyazoid = request.cookies["GyazoID"]

File.open("/tmp/gyazoid","w"){ |f|
  f.puts gyazoid
}
  idimage = SDBM.open("#{FILEROOT}/idimage",0644)
  uploadedimages = idimage[gyazoid].to_s.split(/,/).collect { |id|
    @imageurl = "http://gyazo.com/#{id}.png"
    erb :icon
  }.join(' ')
end

if $0 == __FILE__ then
  puts uploaded_html
end

