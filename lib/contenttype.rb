# -*- coding: utf-8 -*-
#
# 拡張子からcontent-typeを得る
#
module ContentType
  TYPE = {}
  TYPE['.txt'] = 'text/plain'
  TYPE['.csv'] = 'text/csv'
  TYPE['.tsv'] = 'text/tab-separated-values'
  TYPE['.doc'] = 'application/msword'
  TYPE['.xls'] = 'application/vnd.ms-excel'
  TYPE['.ppt'] = 'application/vnd.ms-powerpoint'
  TYPE['.pptx'] = 'application/vnd.ms-powerpoint'
  TYPE['.pdf'] = 'application/pdf'
  TYPE['.xdw'] = 'application/vnd.fujixerox.docuworks'
  TYPE['.html'] = 'text/html'
  TYPE['.html'] = 'text/html'
  TYPE['.css'] = 'text/css'
  TYPE['.js'] = 'text/javascript'
  TYPE['.hdml'] = 'text/x-hdml'
  TYPE['.jpg'] = 'image/jpeg'
  TYPE['.jpeg'] = 'image/jpeg'
  TYPE['.png'] = 'image/png'
  TYPE['.gif'] = 'image/gif'
  TYPE['.bmp'] = 'image/bmp'
  TYPE['.ai'] = 'application/postscript'
  TYPE['.mp3'] = 'audio/mpeg'
  TYPE['.wav'] = 'audio/x-wav'
  TYPE['.m4a'] = 'video/mp4'
  TYPE['.mp4'] = 'video/mp4'
  TYPE['.m4v'] = 'video/m4v'
  TYPE['.mid'] = 'audio/midi'
  TYPE['.midi'] = 'audio/midi'
  TYPE['.mmf'] = 'application/x-smaf'
  TYPE['.mpg'] = 'video/mpeg'
  TYPE['.mpeg'] = 'video/mpeg'
  TYPE['.mov'] = 'video/quicktime'
  TYPE['.wmv'] = 'video/x-ms-wmv'
  TYPE['.flv'] = 'video/flv'
  TYPE['.wmv'] = 'video/x-ms-wmv'
  TYPE['.avi'] = 'video/x-msvideo'
  TYPE['.swf'] = 'application/x-shockwave-flash'
  TYPE['.3g2'] = 'video/3gpp2'
  TYPE['.zip'] = 'application/zip'
  TYPE['.lha'] = 'application/x-lzh'
  TYPE['.lzh'] = 'application/x-lzh'
  TYPE['.tar'] = 'application/x-tar'
  TYPE['.tgz'] = 'application/x-tar'
  TYPE['.exe'] = 'application/octet-stream'
  TYPE['.eps'] = 'application/postscript'
  TYPE['.ps'] = 'application/postscript'
  TYPE['.graffle'] = 'application/x-omnigraffle'
  TYPE['.apk'] = 'application/vnd.android.package-archive'
  TYPE['.dmg'] = 'application/x-apple-diskimage'
  TYPE['.'] = ''
  TYPE[''] = ''
end

def contenttype(ext)
  ContentType::TYPE[ext.downcase]
end

