helpers do

  def escape_jsvar(str)
    str.gsub("'"){ "\\'" }
  end

  def escape_html(str)
    Rack::Utils.escape_html str
  end

  def app_root()
    "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{env['SCRIPT_NAME']}"
  end

  def sanitize(s)
    s.gsub(/&/,'&amp;').gsub(/</,'&lt;')
  end

  def writable?(wiki,request)
    wiki.has_no_auth_pages? ||
      (wiki.password_required? && wiki.password_authorized?(request)) ||
      (wiki.all_auth_page.exist? && wiki.all_auth_page.cookie_authorized?(request)) ||
      (wiki.write_auth_page.exist? && wiki.write_auth_page.cookie_authorized?(request))
  end
end
