# encoding: utf-8

Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"

class Weather
    include Cinch::Plugin

	# Check the DB for stored locations

	def get_location(m, param) 
		if param == '' || param.nil?
			location = LocationDB.first(:nick => m.user.nick.downcase)
			if location.nil?
				m.reply "location not provided nor on file."
				return nil
			else
				return location.location
			end
		else
			return param.strip
		end
	end 


	match /w(?:e(?:ather)?)?(?: (.+))?$/iu, method: :weather
	def weather(m, loc = nil)
		return unless ignore_nick(m.user.nick).nil?

		location = get_location(m, loc)
		return if location.nil?

		begin
        
            wunderground = Wunderground.new($WUNDERGROUNDAPI)
            wunderground.throws_exceptions = true
            argument = URI.escape(location)
            
            conditions = wunderground.conditions_for argument
            
            city        = conditions["current_observation"]["display_location"]["full"]
            condition   = conditions["current_observation"]["weather"]
            tempc       = conditions["current_observation"]["temp_c"]
            tempf       = conditions["current_observation"]["temp_f"]
            humidity    = conditions["current_observation"]["relative_humidity"]
            wind_mph    = conditions["current_observation"]["wind_mph"]
            wind_kph    = conditions["current_observation"]["wind_kph"]
            wind_dir    = conditions["current_observation"]["wind_dir"]
            
            temp        = "#{tempc}C (#{tempf}F)"
            wind        = "From #{wind_dir} at #{wind_kph} KPH (#{wind_mph} MPH)"
        
#			url = Nokogiri::XML(open("http://www.google.com/ig/api?weather=#{argument}").read)
#			url.encoding = 'utf-8'

#			city        = url.xpath("//forecast_information/city/@data")
#			condition   = url.xpath("//current_conditions/condition/@data")
#			tempc       = url.xpath("//current_conditions/temp_c/@data")
#			tempf       = url.xpath("//current_conditions/temp_f/@data")
#			humidity    = url.xpath("//current_conditions/humidity/@data")
#			wind        = url.xpath("//current_conditions/wind_condition/@data")
#
#			city        = Iconv.conv("UTF-8", 'ISO-8859-1', city.to_s)

			return unless city.length > 1

			text = "#{city} | #{condition} #{temp}. Humidity: #{humidity}. Wind: #{wind}"

            m.reply "Weather | #{text}"
		rescue Exception => e
			m.reply "Error getting weather for #{loc}: #{e.message}"
		end
	end

	match /f(?:o(?:recast)?)?(?: (.+))?$/iu, method: :forecast
	def forecast(m, loc = nil)
		return unless ignore_nick(m.user.nick).nil?

		location = get_location(m, loc)
		return if location.nil?

		begin
			argument = URI.escape(location)
			url = Nokogiri::XML(open("http://www.google.com/ig/api?weather=#{argument}").read)
			url.encoding = 'utf-8'

			forecast  = url.xpath("//forecast_conditions")
			city      = url.xpath("//forecast_information/city/@data")
			city      = Iconv.conv("UTF-8", 'ISO-8859-1', city.to_s)
			text      = "#{city} | "

			return unless city.length > 1

			forecast.each do |cond|
				day         = cond.xpath("day_of_week/@data")
				condition   = cond.xpath("condition/@data")

				high        = cond.xpath("high/@data")
				low         = cond.xpath("low/@data")

				highC       = (("#{high}".to_i)-32.0)*(5.0/9.0)
				lowC        = (("#{low}".to_i)-32.0)*(5.0/9.0)

				text = text + "#{day}: #{condition} #{highC.round}°C/#{lowC.round}°C (#{high}°F/#{low}°F) | "
			end
			text = text[0..text.length-4]
		rescue 
			text = "Error getting forecast for #{loc}"
		end
		m.reply "Forecast | #{text}"
	end
end