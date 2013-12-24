require 'rss/maker'

def rss(name)
  hotids = hotidlist(name)

  rss = RSS::Maker.make("2.0") do |rss|
    rss.channel.about = "http://Gyazz.com/#{name}/rss.xml"
    rss.channel.title = "Gyazz - #{name}"
    rss.channel.description = "Gyazz - #{name}"
    rss.channel.link = "http://Gyazz.com/#{name}"
    rss.channel.language = "ja"
  
    rss.items.do_sort = true
    rss.items.max_size = 15

    hotids[0...15].each { |id|
      i= rss.items.new_item
      title = @id2title[id]
      i.title = title
      i.link = "http://Gyazz.com/#{name}/#{title}"
      i.date = @modtime[id]
      i.description = (password_required?(name) ? i.date.to_s : readdata(name,title,0))
      # i.description = readdata(name,title,0)
    }
  end

  rss.to_s
end

if $0 == __FILE__ then
  puts rss('masui')
end
