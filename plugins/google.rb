# encoding: utf-8

class Google
    include Cinch::Plugin

	match /g(?:oogle)? (.+)/i

	def execute(m, query)
		return unless ignore_nick(m.user.nick).nil?
		begin

			@bitly = Bitly.new($BITLYUSER, $BITLYAPI)

			@url = open("https://encrypted.google.com/search?hl=en&q=#{URI.escape(query)}", "User-Agent" => "Lynx/2.8.6rel.5 libwww-FM/2.14")
			@url = Nokogiri::HTML(@url)

			def search(number)
				title    = @url.xpath("//p[#{number}]/a").inner_html.gsub(/<\/?b>/, '')
				url      = @url.xpath("//table[#{number+3}]/tr/td[@class='j']/font/a[last()]/@href").text.gsub('/search?q=related:', '').gsub('&hl=en', '')

				"Google 2| %s 2| %s" % [title, url]
			end

			more  = @bitly.shorten("https://encrypted.google.com/search?hl=en&q=#{URI.escape(query)}")

			m.reply search(1)
			#m.reply search(2)
			m.reply "Google 2| More results #{more.shorten}"
		rescue
			m.reply "Google 2| Error"
		end
	end
end