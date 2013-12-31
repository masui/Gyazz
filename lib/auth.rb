# -*- coding: utf-8 -*-
#
# 認証関連
#
# * パスワードとなぞなぞ認証を利用する
# * 3種類の認証レベルが存在する
#  - 認証なし
#    誰でも読み書きできる
#  - 完全認証
#    認証されると読み書き可能/認証されていないと読むこともできない
#  - 書込認証
#    誰でも読めるが認証されないと書込みできない
#
# * パスワード認証
#  - BASIC認証
#  - 「.password」または「.passwd」というページにユーザ名とパスワードを2行で記述
#
# * なぞなぞ認証
#  - 「.完全認証」というページのなぞなぞに正しく回答すると完全認証される
#  - 「.書込認証」というページのなぞなぞに正しく回答すると書込認証される
#
# * 認証レベルの決定
#  - 認証関連ページが存在しない場合は「認証なし」
#  - 「.password」「.passwd」「.完全認証」ページがある場合は「完全認証」
#  - 「.書込み認証」だけある場合は「書込認証」
#
# * なぞなぞ認証
#  - 「.完全認証」「.書込認証」ページになぞなぞ問題と答を記述する
#   問題1
#    答1
#    答2
#   問題2
#    答3
#    答4
#  - 答1, 答3が正解であり、ユーザがそれを選んだとき認証が成功する
#  - 認証されてない状態では答が並べかえらて表示される
#  - これらのページには常にアクセス可能
#  - 正しい答をクリックすると認証成功する
#

module Gyazz
  class Wiki
    def has_no_auth_pages?
      !password_required? && !auth_page_exist?
    end
  end
end

#
# パスワード認証
#
module Gyazz
  class Wiki
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
# なぞなぞ認証
#
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
    def is_all_auth_page?
      title == ALL_AUTH
    end

    def is_write_auth_page?
      title == WRITE_AUTH
    end

    def is_auth_page?
      is_all_auth_page? || is_write_auth_page?
    end

    def randomtext
      result = ""
      buf = []
      a = text.split(/\n/)
      a.each_with_index { |s,i|
        if s =~ /^\S/ then
          result += buf.sort_by { rand }.join("\n")
          result += "\n" if result != ""
          result += "#{s}\n"
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
      request.cookies[auth_cookie].to_s != ''
    end

  end
end




