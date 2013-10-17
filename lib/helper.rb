# -*- coding: utf-8 -*-
## viewでのみ使えるhelperを書く

helpers do

  ## http://www.sinatrarb.com/faq.html#auto_escape_html
  ## を使うと既存のページ名が変更されてしまうので、手動でescapeする
  def escape_html(str)
    str.gsub("'"){ "\\'" }
  end

end
