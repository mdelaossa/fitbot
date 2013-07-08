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
				title    = @url.xpath("//p/a").first.inner_html.gsub(/<\/?b>/, '')
				url      = @url.xpath("//p/a").first.attributes["href"].value.gsub('/url?q=','').gsub(/&.+=.+/,'')

				"Google | %s | %s" % [title, url]
			end

			more  = @bitly.shorten("https://encrypted.google.com/search?hl=en&q=#{URI.escape(query)}")

			m.reply search(1)
			#m.reply search(2)
			m.reply "Google | More results #{more.shorten}"
		rescue
			m.reply "Google | Error"
		end
	end
end