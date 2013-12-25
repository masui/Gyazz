class Time
  def stamp
    self.strftime('%Y%m%d%H%M%S')
  end
end

class String
  def to_time
    self =~ /^(....)(..)(..)(..)(..)(..)/
    Time.local($1.to_i,$2.to_i,$3.to_i,$4.to_i,$5.to_i,$6.to_i)
  end
end


