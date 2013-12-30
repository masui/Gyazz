# -*- coding: utf-8 -*-
#
# なぞなぞ認証とパスワード認証
#
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
    def no_auth?
      !password_required? && !auth_page_exist?
    end

    def password_authorized?(request)
      return false if !password_required?

      user,pass = password_data
      return false if user.to_s == '' || pass.to_s == ''

      auth =  Rack::Auth::Basic::Request.new(request.env)
      auth.provided? && auth.basic? && auth.credentials && auth.credentials == [user,pass]
    end

    def password_data
      text = Page.new(self,".passwd").text
      text = Page.new(self,".password").text if text == ''
      text.split # password[0]=>user, password[1]=>pass
    end

    def password_required?
      Gyazz::Page.new(self,".passwd").text != '' || 
        Gyazz::Page.new(self,".password").text != ''
    end
  end
end

#
# なぞなぞ認証のためのもの

module Gyazz
  ALL_AUTH = '.完全認証'
  WRITE_AUTH = '.書込認証'

  class Wiki
    def all_auth_page
      Page.new(self,ALL_AUTH)
    end

    def write_auth_page
      Page.new(self,WRITE_AUTH)
    end

    def auth_page_exist?
      all_auth_page.text != '' || write_auth_page.text != ''
    end
  end

  class Page
    def all_auth_page?
      title == ALL_AUTH
    end

    def write_auth_page?
      title == WRITE_AUTH
    end

    def auth_page?
      all_auth_page? || write_auth_page?
    end

    def randomtext
      result = ""
      buf = []
      a = text.split(/\n/)
      a.each_with_index { |s,i|
        if s =~ /^\S/ then
          result += buf.sort_by { rand }.join("\n")
          result += "\n#{s}\n"
          buf = []
        else
          buf << s
        end
      }
      result += buf.sort_by { rand }.join("\n")
    end

    def authanswer
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

    def auth_cookie # 認証用クッキーの名前
      (wiki.name + title + text).md5
    end

    def cookie_authorized?(request)
      val = request.cookies[auth_cookie].to_s != ''
      puts "cookie_authorized? = #{val}"
      puts "password_authorized? = #{wiki.password_authorized?(request)}"
      val
    end

  end
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



