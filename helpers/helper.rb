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

end
