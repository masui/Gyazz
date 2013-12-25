def readdata(name,title,version=nil)
  file = Gyazz.datafile(name,title,version)
  ret = {}
  datestr = ""
  if version && version > 0 then
    file =~ /\/(\d{14})$/
    ret['date'] = $1
  end
  data = File.exist?(file) ? File.read(file)  : ''
  data = data.sub(/\n+$/,'').split(/\n/)
  ret['data'] = data
  if version && version > 0 then
    ret['age'] = data.collect { |line|
      line = line.chomp.sub(/^\s*/,'')
      t = line_timestamp(name,title,line).to_time
      (Time.now - t).to_i
    }
  end
  ret
end
