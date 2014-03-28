module Gyazz

  class Page

    def suggest_similartitles
      titles = wiki.validpages.map{|page| page.title }

      pattern = ::Asearch.new title.strip
      similar_titles = []
      1.upto(2) do |level|
        titles.each do |i|
          if i != title and pattern.match(i, level)
            similar_titles << i.gsub(/"/,'\"')
          end
        end
        break unless similar_titles.empty?
      end
      similar_titles
    end

  end

end
