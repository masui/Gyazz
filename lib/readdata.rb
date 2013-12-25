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
    ret['timestamp'] = data.collect { |line|
      line = line.chomp.sub(/^\s*/,'')
      line_timestamp(name,title,line) =~ /(....)(..)(..)(..)(..)(..)/
      t = Time.local($1.to_i,$2.to_i,$3.to_i,$4.to_i,$5.to_i,$6.to_i)
      (Time.now - t).to_i
    }
  end
  ret
end
