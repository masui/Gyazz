def readdata(name,title,version=nil)
  file = Gyazz.datafile(name,title,version)
  datestr = ""
  if version && version > 0 then
    file =~ /\/(\d{14})$/
    datestr = $1
  end
  data = File.exist?(file) ? File.read(file)  : ''

  if version && version > 0 then
    a = []
    data.each_line { |line|
      line = line.chomp.sub(/^\s*/,'')
      line_timestamp(name,title,line) =~ /(....)(..)(..)(..)(..)(..)/
      t = Time.local($1.to_i,$2.to_i,$3.to_i,$4.to_i,$5.to_i,$6.to_i)
      td = (Time.now - t).to_i
      a << "#{line} #{td}"
    }
    data = a.join("\n")
  end

  version ? datestr + "\n" + data : data
end

