def edit
  #@name = @page.wiki.name
  #puts @name
  #puts "================="
  #@title = @page.title

  # file = Gyazz.datafile(name,title,version)
  # @text = File.exist?(file) ? File.read(file)  : ''
  # @text = @page.text

  # @text =~ /^\s*$/ ? "(empty)" : @text
  # @text.gsub!(/&/,'&amp;') # 2012/04/23 04:44:29 masui ????
  # @text.gsub!(/</,'&lt;') # 2012/10/24 14:32:15 masui

  # @orig_md5 = @text.md5

  #@write_authorized = false
  #@write_authorized = true if password_authorized?(@name)
  #@write_authorized = true if cookie_authorized?(@name,ALL_AUTH)
  #@write_authorized = true if cookie_authorized?(@name,WRITE_AUTH)
  #@write_authorized = true
end
