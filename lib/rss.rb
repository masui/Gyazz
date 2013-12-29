module Gyazz
  class Wiki
    def rss(root='http://Gyazz.com/')
      rss = RSS::Maker.make("2.0") do |rss|
        rss.channel.about = "#{root}/#{name}/rss.xml"
        rss.channel.title = "Gyazz - #{name}"
        rss.channel.description = "Gyazz - #{name}"
        rss.channel.link = "#{root}/#{name}"
        rss.channel.language = "ja"
        
        rss.items.do_sort = true
        rss.items.max_size = 15
        
        disppages[0...15].each { |page|
          i = rss.items.new_item
          i.title = page.title
          i.link = "#{root}/#{name}/#{page.title}"
          i.date = page.modtime
          i.description = (password_required? ? i.date.to_s : page.text)
        }
      end
      rss.to_s
    end
  end
end
