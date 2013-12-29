# -*- coding: utf-8 -*-
#
# なぞなぞ認証のためのライブラリ
# * 以下のようなGyazzファイルを認証につかう。
# * 答1, 答3が正解であり、ユーザがそれを選んだとき認証が
#   成功するようにする
# * ユーザには答を並べかえたものを指定する
# * ユーザから正しい答が返ってきたら認証成功
#
# 画像1
#  答1
#  答2
# 画像2
#  答3
#  答4
#

######################################
#
# パスワード認証
#
module Gyazz
  class Wiki
    def password_required?
      Gyazz::Page.new(self,".passwd").curdata != '' || 
        Gyazz::Page.new(self,".password").curdata != ''
    end
    #      file = Gyazz.datafile(name,".passwd") || Gyazz.datafile(name,".password")
    #    File.exist?(file) ? file : nil
  end
end


  def protected!(name)
    unless password_authorized?(name)
      response['WWW-Authenticate'] = %(Basic realm="#{name}")
      throw(:halt, [401, "Not authorized.\n"])
    end
  end

  def password_required?(name)
    file = Gyazz.datafile(name,".passwd") || Gyazz.datafile(name,".password")
    File.exist?(file) ? file : nil
  end
  
  def password_authorized?(name)
    # file = Gyazz.datafile(name,".passwd") || Gyazz.datafile(name,".password")
    # return true unless File.exist?(file)
    file = password_required?(name)
    return true unless file
    a = File.read(file).split
    user = a.shift
    pass = a.shift
    return true if user.to_s == '' || pass.to_s == ''
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [user,pass]
  end

######################################

def check_auth(name)
  authorized_by_cookie = false
  if auth_page_exist?(name,ALL_AUTH) then
    if cookie_authorized?(name,ALL_AUTH) then
      authorized_by_cookie = true
    end
  end
  # 前はこうなっていた。変だと思うが何故放置されてたのか...? (2013/03/16 11:40:44)
  #authorized_by_cookie = true
  #if auth_page_exist?(name,ALL_AUTH) then
  #  if !cookie_authorized?(name,ALL_AUTH) then
  #    authorized_by_cookie = false
  #  end
  #end

  if !password_authorized?(name) then
    if !authorized_by_cookie then
      response['WWW-Authenticate'] = %(Basic realm="#{name}")
      throw(:halt, [401, "Not authorized.\n"])
    end
  end
end

######################################
#
# なぞなぞ認証のためのもの
#

module Gyazz
  ALL_AUTH = '.完全認証'
  WRITE_AUTH = '.書込認証'

  class Page
    def all_auth_page?
      title == ALL_AUTH
    end

    def write_auth_page?
      title == WRITE_AUTH
    end

    def auth_page?
      puts title
      all_auth_page? || write_auth_page?
    end

    def randomtext
      result = ""
      buf = []
      a = text.split(/\n/)
      a.each_with_index { |s,i|
        if s =~ /^\S/ then
          result += buf.sort_by { rand }.join("\n")
          result += "#{s}\n"
          buf = []
        else
          buf << s
        end
      }
      result += buf.sort_by { rand }.join("\n")
    end

    def anstext
      result = []
      buf = []
      a = text.split(/\n/)
      a.each_with_index { |s,i|
        if s =~ /^\S/ then
          result << buf[0] if buf.length > 0
          buf = []
        else
          buf << s
        end
      }
      result << buf[0] if buf.length > 0
      result.sort.join(",")
    end

  end

  class Wiki
    def auth_page_exist?(name)
      Page.new(self.name).text
      File.exist?(Gyazz.datafile(name,title)) && File.read(Gyazz.datafile(name,title)).gsub(/[\n\s]/,'') != ""
    end
  end

end

def auth_cookie(name,title)
  data = readdata(name,title)
  Gyazz.md5(name + title + data)
end

def cookie_authorized?(name,title)
  request.cookies[auth_cookie(name,title)].to_s != ''
end

if $0 == __FILE__ then
  s = <<EOF
[[gyazo.png]]
 A
 B
 C
 D
 E
[[gyazo2.png]]
 F
 G
2+3=
 4
 5
 6
 7
 8
aaaa
bbbbb
 jjjj
  nn
EOF

  print randomize(s)
  puts ansstring(s)
end






