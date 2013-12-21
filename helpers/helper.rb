helpers do

  def escape_html(str)
    str.gsub("'"){ "\\'" }
  end

  def app_root()
    "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{env['SCRIPT_NAME']}"
  end

  def topurl(name)
    "#{app_root}/#{name}"
  end

  def sanitize(s)
    s.gsub(/&/,'&amp;').gsub(/</,'&lt;')
  end


end
