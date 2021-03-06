# encoding: utf-8

class Twitter
    include Cinch::Plugin
    include UtilityFunctions

	match /tw(?:itter)? (.+)/i

	def minutes_in_words(timestamp)
		minutes = (((Time.now - timestamp).abs)/60).round

		return nil if minutes < 0

		case minutes
		when 0..1      then "just now"
		when 2..59     then "#{minutes.to_s} minutes ago"
		when 60..1439        
			words = (minutes/60)
			if words > 1
				"#{words.to_s} hours ago"
			else
				"#{words.to_s} hour ago"
			end
		when 1440..11519     
			words = (minutes/1440)
			if words > 1
				"#{words.to_s} days ago"
			else
				"#{words.to_s} day ago"
			end
		when 11520..43199    
			words = (minutes/11520)
			if words > 1
				"#{words.to_s} weeks ago"
			else
				"#{words.to_s} week ago"
			end
		when 43200..525599   
			words = (minutes/43200)
			if words > 1
				"#{words.to_s} months ago"
			else
				"#{words.to_s} month ago"
			end
		else                      
			words = (minutes/525600)
			if words > 1
				"#{words.to_s} years ago"
			else
				"#{words.to_s} year ago"
			end
		end
	end

	def execute(m, query)
		return unless ignore_nick(m.user.nick).nil?

		begin
			url = Nokogiri::XML(open("http://api.twitter.com/1/statuses/user_timeline.xml?screen_name=#{query}&count=1&include_rts=true&exclude_replies=true&include_entities=true", :read_timeout=>3).read)

			tweettext   = url.xpath("//status/text").text.gsub(/\s+/, ' ')
			posted      = url.xpath("//status/created_at").text
			name        = url.xpath("//statuses/status/user/name").text
			screenname  = url.xpath("//statuses/status/user/screen_name").text

			urls        = url.xpath("//status/entities/urls/url")

			urls.each do |rep|
				shortened   = rep.xpath("url").text
				expanded    = rep.xpath("expanded_url").text
				tweettext   = tweettext.gsub(shortened, expanded)
			end

			time        = Time.parse(posted)
			time        = minutes_in_words(time)

			m.reply "Twitter | #{name} (@#{screenname}) | #{tweettext} | Posted #{time}"
		rescue Timeout::Error
			m.reply "Twitter | Timeout Error. Maybe twitter is down?"
		rescue
			m.reply "Twitter | #{query} | Could not get tweet"
		end
	end
end