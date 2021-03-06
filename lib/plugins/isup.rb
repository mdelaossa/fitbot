# encoding: utf-8

class IsUp
    include Cinch::Plugin
    include UtilityFunctions
    require 'uri'
    require 'net/http'

	match /isup (.+)/i, method: :isup

	def isup(m, word)
		return unless ignore_nick(m.user.nick).nil?

		begin
			#url = CGI.escape(word)
			#isup = Nokogiri::HTML(open(url))
			#resp = Net::HTTP.get_response(URI.parse(word))
			
			response = nil
            Net::HTTP.start(word, 80) {|http|
             response = http.head(word)
            }
            resp = response.code
			
			if resp == '200'
			    m.reply "IsUp | #{word} | Seems up to me! Sucks to be you."
			else
			    m.reply "IsUp | #{word} | Seems down to me"
			end
		rescue
			m.reply "IsUp | #{word} | Seems down to me"
		end
	end
end