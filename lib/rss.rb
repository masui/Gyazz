require 'rss/maker'

def rss(name,root='http://Gyazz.com/')
  wiki = Gyazz::Wiki.new(name)
  hotids = wiki.hotids

  rss = RSS::Maker.make("2.0") do |rss|
    rss.channel.about = "#{root}/#{name}/rss.xml"
    rss.channel.title = "Gyazz - #{name}"
    rss.channel.description = "Gyazz - #{name}"
    rss.channel.link = "#{root}/#{name}"
    rss.channel.language = "ja"
  
    rss.items.do_sort = true
    rss.items.max_size = 15

    hotids[0...15].each { |id|
      title = Gyazz.id2title(id)
      next if title =~ /^\./
      i= rss.items.new_item
      i.title = title
      i.link = "#{root}/#{name}/#{title}"
      page = Gyazz::Page.new(wiki,title)
      i.date = page.modtime
      i.description = (wiki.password_required? ? i.date.to_s : page.text)
    }
  end

  rss.to_s
end

