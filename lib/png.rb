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