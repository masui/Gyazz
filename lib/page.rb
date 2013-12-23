# -*- coding: utf-8 -*-

def page(name,title,write_authorized=false)
  allaccess = SDBM.open("#{FILEROOT}/access",0644);
  s = "#{name}(#{Gyazz.md5(name)})/#{title}(#{Gyazz.md5(title)})"
  allaccess[s] = (allaccess[s].to_i + 1).to_s
  allaccess.close

  searchable = false
  if File.exist?("#{Gyazz.topdir(name)}/attr.dir") then
    attr = SDBM.open("#{Gyazz.topdir(name)}/attr",0644);
    searchable = (attr['searchable'] == 'true' ? true : false)
    attr.close
  end
  @robotspec = (searchable ? "index,follow" : "noindex,nofollow")

  @do_auth = false
  data_file = Gyazz.datafile(name,title)
  if File.exist?(data_file) then
    @rawdata = File.read(data_file)
    if title == ALL_AUTH then
      if !cookie_authorized?(name,ALL_AUTH) then
        @rawdata = randomize(@rawdata)
        @do_auth = true
      end
    elsif title == WRITE_AUTH then
      if !cookie_authorized?(name,WRITE_AUTH) then
        @rawdata = randomize(@rawdata)
        @do_auth = true
      end
    end
  end
  @write_authorized = write_authorized

  #
  # アクセス履歴をバックアップディレクトリに保存
  # ちょっと変だがとりあえず...
  # readdata() でやるよりここの方がよいようだ (2012/04/14 13:45:53)
  #
  if File.exists?("#{Gyazz.backupdir(name,title)}") then
    File.open("#{Gyazz.backupdir(name,title)}/access","a"){ |f|
      f.puts Time.now.strftime('%Y%m%d%H%M%S')
    }
  end

  page = {}
  page['name'] = name
  page['title'] = title
  page['related'] = related_html(name,title)

  page

  # response["Access-Control-Allow-Origin"] = "*"
end
