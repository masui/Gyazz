# -*- coding: emacs-mule -*-

module Gyazz
  # FILEROOT = "/Users/masui/Gyazz/data"             # Gyazz’¥Ç’¡¼’¥¿’¥Ç’¥£’¥ì’¥¯’¥È’¥ê
  FILEROOT = "/tmp"

  # DEFAULTPAGE = "/index.html"
  DEFAULTPAGE = "/Gyazz/#{URI.encode('’ÌÜ’¼¡')}"

  SESSION_SECRET = "this is session secret (please change)" 
end

