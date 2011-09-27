# -*- coding: utf-8 -*-

require 'config'
require 'lib'

def history(name,title)
  dir = backupdir(name,title)
  timestamps = Dir.open(dir).find_all { |file|
    file =~ /^\d{14}$/
  }
  now = Time.now
  max = 25
  v = []
  timestamps.each { |timestamp|
    timestamp =~ /^(....)(..)(..)(..)(..)(..)/
    t = Time.local($1.to_i,$2.to_i,$3.to_i,$4.to_i,$5.to_i,$6.to_i)
    if true then # 羃的
      d = (now - t).to_i / (60 * 60 * 24) # 時間
      d = 1 if d == 0
      ind = (Math.log(d) / Math.log(1.3)).floor
      ind = max-1 if ind >= max
      v[ind] = v[ind].to_i + 1
    elsif true then # リニア
      ind = (now - t).to_i / (60 * 60 * 24 * 30)
      ind = max-1 if ind >= max
      v[ind] = v[ind].to_i + 1
    else # フィボナッチ
      # 1, 2, 3, 5, 8, 13, ...
      fib = []
      fib[0] = 1
      fib[1] = 2
      (0..max).each { |i|
        fib[i+2] = fib[i] + fib[i+1]
      }
      d = (now - t).to_i / (60 * 60 * 4)
      ind = max-1
      (0..max-1).each { |i|
        if fib[i] >= d then
          ind = i
          break
        end
      }
      v[ind] = v[ind].to_i + 1
    end
  }
  "[" + (0..max-1).collect { |i|
    v[max-i-1].to_i.to_s
  }.join(",") + "]"
end

