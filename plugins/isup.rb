# encoding: utf-8

class IsUp
    include Cinch::Plugin
    require 'uri'
    require 'net/http'

	match /isup (.+)/i, method: :isup

	def isup(m, word)
		return unless ignore_nick(m.user.nick).nil?

		begin
			#url = CGI.escape(word)
			#isup = Nokogiri::HTML(open(url))
			resp = Net::HTTP.get_response(URI.parse(word))
			
			if resp.code.match('200')
			    m.reply "IsUp | #{word} | Seems up to me! Sucks to be you."
			else
			    m.reply "IsUp | #{word} | Seems down to me"
			end
		rescue
			m.reply "IsUp | #{word} | Error occurred"
		end
	end
end