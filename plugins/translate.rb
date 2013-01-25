# encoding: utf-8

class Translate
    include Cinch::Plugin

	match /t(?:r(?:anslate)?)? ([a-zA-Z-]{2,6}) ([a-zA-Z-]{2,6}) (.*)/iu

	def execute(m, from, to, message)
		return unless ignore_nick(m.user.nick).nil?

		begin
			url = open("http://api.microsofttranslator.com/V2/Ajax.svc/Translate?appId=#{$BINGAPI}&from=#{from}&to=#{to}&text=#{CGI.escape(message)}").read
			url = url[1..url.length] # cut off some weird character at the start of the string

			if url.include? "ArgumentOutOfRangeException" and url.include? "'from'"
				m.reply "Translate 11| '#{from}' is not a supported language code 11| #{$BOTURL}#translate"
			elsif url.include? "ArgumentOutOfRangeException" and url.include? "'to'"
				m.reply "Translate 11| '#{to}' is not a supported language code 11| #{$BOTURL}#translate"
			else
				m.reply "Translate 11| #{from} => #{to} 11| #{url}"
			end
		rescue
			m.reply "Translate 11| Error: Could not get translation"
		end
	end
end