# -*- coding: utf-8 -*-

#
# * アクセス履歴と編集履歴をどう表示するべきか
# * 古い重要なページはアクセス履歴だけたまってくるはず
# * ずっと編集され続けるページもあるだろう
# * 両方を一目了然に表示したい
#

module Gyazz
  MAX = 25
  MAXH = 12

  class Page
    # 古い変更/新しい変更を考慮して履歴を視覚化する
    def log(history)
      now = Time.now
      v = []
      history.each { |timestamp|
        t = timestamp.to_time
        #
        # issue #59 を参照
        # 羃的に計算する
        #
        d = (now - t).to_i / (60 * 60 * 24) # 時間
        d = 1 if d == 0
        ind = (Math.log(d) / Math.log(1.5)).floor
        ind = MAX-1 if ind >= MAX
        v[ind] = v[ind].to_i + 1
      }
      (0..MAX).collect { |i|
        (Math.log(v[i].to_i+0.9) * 3).to_i
      }
    end

    # v[n] に対応する大体の日付を計算する
    def vis_timestamp(n)
      (Time.now - Math.exp(n * Math.log(1.5)).ceil * 60 * 60 * 24).stamp
    end
    
    # PNG視覚化
    def modify_png
      alog = log(access_history)
      mlog = log(modify_history)
      data = []

      #
      # 新しいものは背景を黄色くする
      #
      hotcolors = [[255,255,0],[255,255,40],[255,255,80],[255,255,120],[255,255,160],[255,255,200]]
      bgcolor = [255,255,255]
      5.downto(0).each { |j|
        bgcolor = hotcolors[j] if mlog[j] > 0
      }
      (0...MAXH).each { |y|
        data[y] = []
        (0...MAX).each { |x|
          data[y][x] = bgcolor
        }
      }
      #
      # 櫛状にアクセスを表示
      #
      (0...MAX).each { |i|
        d = alog[i]
        d = MAXH if d >= MAXH
        c = 8 - (alog[i]/10)
        c = 0 if c < 0
        (0...d).each { |y|
          # data[MAXH-y-1][MAX-i-1] = [c*20, c*20, c*20]
          # data[MAXH-y-1][MAX-i-1] = [0,0,255]
          data[MAXH-y-1][MAX-i-1] = [128,128,128]
        }
      }
      (0...MAX).each { |i|
        d = mlog[i]
        d = MAXH/2 if d >= MAXH/2
        (0...d).each { |y|
          data[MAXH-y-1][MAX-i-1] = [0,0,0]
        }
      }
      PNG.png(data)
    end

  end
end

