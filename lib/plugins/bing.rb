# encoding: utf-8

class Bing
    include Cinch::Plugin
    include UtilityFunctions

	match /b(?:ing)? (.+)/i

	def execute(m, query)
		return unless ignore_nick(m.user.nick).nil?
		begin

			@bitly = Bitly.new($CONFIG.apis.bitly.user, $CONFIG.apis.bitly.api)

			@url = open("http://api.bing.net/xml.aspx?AppId=#{$CONFIG.apis.bing}&Version=2.1&Market=en-US&Query=#{URI.escape(query)}&Sources=web&Web.Count=2&Options=EnableHighlighting&Web.Options=DisableQueryAlterations+DisableHostCollapsing")
			@url = Nokogiri::XML(@url)

			def search(number)
				title      = @url.xpath("//web:WebResult[#{number}]/web:Title", {"web" => "http://schemas.microsoft.com/LiveSearch/2008/04/XML/web"}).text
				desc       = @url.xpath("//web:WebResult[#{number}]/web:Description", {"web" => "http://schemas.microsoft.com/LiveSearch/2008/04/XML/web"}).text
				url        = @url.xpath("//web:WebResult[#{number}]/web:Url", {"web" => "http://schemas.microsoft.com/LiveSearch/2008/04/XML/web"}).text

				title = title.gsub(/(|)/, "")
				desc = desc.gsub(/(|)/, "")

				"Bing | \"%s\" %s… | %s" % [title, desc[0..100], url]
			end

			more  = @bitly.shorten("http://www.bing.com/search?q=#{URI.escape(query)}")

			m.reply search(1)
			m.reply search(2)
			m.reply "Bing | More results #{more.shorten}"
		rescue
			m.reply "Bing | Error"
		end
	end
end