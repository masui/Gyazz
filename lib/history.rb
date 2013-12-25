# -*- coding: utf-8 -*-

MAX = 25
MAXH = 12

#
# アクセス履歴タイムスタンプ
#
def access_history(name,title,append=nil)
  if append then # 追記
    if File.exists?("#{Gyazz.backupdir(name,title)}") then
      File.open("#{Gyazz.backupdir(name,title)}/access","a"){ |f|
        f.puts Time.now.stamp
      }
    end
  else
    accessfile = "#{Gyazz.backupdir(name,title)}/access"
    (File.exist?(accessfile) ? File.open(accessfile).read.split : [])
  end
end

#
# 変更履歴タイムスタンプ
#
def modify_history(name,title)
  old_modify_history(name,title).push(File.mtime(Gyazz.datafile(name,title)).stamp)
end

def old_modify_history(name,title)
  dir = Gyazz.backupdir(name,title)
  return '' unless File.exist?(dir)
  Dir.open(dir).find_all { |f|
    f =~ /^\d{14}$/
  }.sort { |a,b|
    a <=> b
  }
end

# 古い変更/新しい変更を考慮して履歴を視覚化する
def modify_log(name,title)
  now = Time.now
  v = []
  modify_history(name,title).each { |timestamp|
    timestamp =~ /^(....)(..)(..)(..)(..)(..)/
    t = Time.local($1.to_i,$2.to_i,$3.to_i,$4.to_i,$5.to_i,$6.to_i)
    #
    # issue #59 を参照
    # 羃的に計算する
    #
    d = (now - t).to_i / (60 * 60 * 24) # 時間
    d = 1 if d == 0
    ind = (Math.log(d) / Math.log(1.3)).floor
    ind = MAX-1 if ind >= MAX
    v[ind] = v[ind].to_i + 1
  }
  (0..MAX).collect { |i| v[i].to_i }
end

# PNG視覚化
def modify_png(name,title)
  v = modify_log(name,title)
  data = []
  hotcolors = [[255,255,0],[255,255,40],[255,255,80],[255,255,120],[255,255,160],[255,255,200]]
  bgcolor = [255,255,255]
  (0..5).each { |j|
    hv = v[j].to_i
    bgcolor = hotcolors[j] if hv > 0
  }
  #####bgcolor = [200,200,200]
  (0...MAXH).each { |y|
    data[y] = []
    (0...MAX).each { |x|
      data[y][x] = bgcolor
    }
  }
  (0...MAX).each { |i|
    d = v[i].to_i
    d = MAXH if d >= MAXH
    c = 8 - (v[i].to_i/10)
    c = 0 if c < 0
    (0...d).each { |y|
      data[MAXH-y-1][MAX-i-1] = [c*20, c*20, c*20]
    }
  }
  PNG.png(data)
end
