# encoding: utf-8

class UrbanDictionary
    include Cinch::Plugin

	match /u(?:r(?:ban)?)? (?:([1-7]{1}) )?(.+)/i, method: :urban

	def urban(m, number, word)
		return unless ignore_nick(m.user.nick).nil?

		begin
			@bitly = Bitly.new($CONFIG.apis.bitly.user, $CONFIG.apis.bitly.api)

			number ||= 1

			url = "http://www.urbandictionary.com/define.php?term=#{CGI.escape(word)}"
			urban = Nokogiri::HTML(open(url))
			define = urban.search("//div[@class='definition']")[number.to_i-1].text.gsub(/\s+/, ' ')

			if define.length > 255
				more = @bitly.shorten("http://www.urbandictionary.com/define.php?term=#{CGI.escape(word)}")
				define = "#{define[0..255]}... #{more.shorten}"
			end

			m.reply "UrbanDictionary | #{word} | #{define}"
		rescue
			m.reply "UrbanDictionary | #{word} | Could not find definition"
		end
	end
end