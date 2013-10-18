# coding: UTF-8
# http://d.hatena.ne.jp/ku-ma-me/20091003/p1
#
# 自力でPNGを作る
#

require "zlib"

class PNG
  def PNG.chunk(type, data)
    chunk = [data.bytesize, type, data, Zlib.crc32(type + data)].pack("NA4A*N")
    RUBY_VERSION < "1.9" ? chunk : chunk.force_encoding("ASCII-8BIT")
  end

  def PNG.png(data,depth=8,color_type=2)
    height = data.length
    width = data[0].length
    out = "\x89PNG\r\n\x1a\n"
    out = out.force_encoding("ASCII-8BIT") unless RUBY_VERSION < "1.9"
    out += PNG.chunk("IHDR", [width, height, depth, color_type, 0, 0, 0].pack("NNCCCCC"))
    img_data = data.map {|line| ([0] + line.flatten).pack("C*") }.join
    out += PNG.chunk("IDAT", Zlib::Deflate.deflate(img_data))
    out += PNG.chunk("IEND", "")
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class PngTest < Test::Unit::TestCase
    TMPFILE = "/tmp/pngtest#{$$}.png"
    
    def setup
    end
    
    def teardown
      File.delete TMPFILE
    end
    
    def test_1
      data = [
              [[255,0,0], [0,255,0]],
              [[0,0,255], [0,0,0]]
             ]
      png = PNG.png(data)
      File.open(TMPFILE,"w"){ |f|
        f.print png
      }
      file = `file #{TMPFILE}`
      # assert file.index("PNG image, 2 x 2, 8-bit/color RGB, non-interlaced")
      assert file =~ %r{PNG.*2 x 2, 8-bit/color RGB, non-interlaced}
    end
    
    def test_2
      data = [
              [[255,0,0], [0,255,0]],
              [[0,0,255], [0,0,0]],
              [[0,0,255], [0,0,0]]
             ]
      png = PNG.png(data)
      File.open(TMPFILE,"w"){ |f|
        f.print png
      }
      file = `file #{TMPFILE}`
      assert !file.index("PNG image, 2 x 2, 8-bit/color RGB, non-interlaced")
    end
  end
end


