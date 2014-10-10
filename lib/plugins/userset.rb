# encoding: utf-8

class UserSet
  include Cinch::Plugin
  include UtilityFunctions
  
  require 'mathn'
  require 'ruby-units'
  
    def to_bool(string)
        return true if string == true || string =~ (/(true|t|yes|y|1|on)$/i)
        return false if string == false ||  string =~ (/(false|f|no|n|0|off)$/i)
        raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
    end
    
    # Set height/weight/sex
    
    match /set height (\d+(?:\.\d+)?)\s?(\w+)/, method: :set_height
    def set_height(m, height, unit) #will be saved in cm
        return unless ignore_nick(m.user.nick).nil?
        begin
            height = Float(height)
            case unit
                when /in(?:ches)?/i
                    height = height * 2.54
                when /f(?:ee)?t/i
                    height = height * 12 * 2.54
                when /c(?:enti)?m(?:eter(?:s)?)?/i
                    height = height
                when /m(?:eter(?:s)?)?/i
                    height = height * 100
                else raise "Invalid unit"
            end
            height = height.round(2)
            Nick.first_or_create(:nick => m.user.nick.downcase).update(:height => height)
            m.reply "Height set to: #{height}cm", true
        rescue Exception => x
            m.reply "Error: #{x.message}"
        end
    end
    
    match /set weight (\d+(?:\.\d+)?)\s?(\w+)/, method: :set_weight
    def set_weight(m, weight, unit) #will be saved in kg
        return unless ignore_nick(m.user.nick).nil?
        begin
            weight = Float(weight)
            case unit
                when /k(?:ilo)?g(?:ram)?s?/i
                    weight
                when /stone/i
                    weight = weight*6.35029318
                when /lbs?|pounds?/i
                    weight = weight/2.20462
                else raise "Invalid unit"
            end
            weight = weight.round(2)
            Nick.first_or_create(:nick => m.user.nick.downcase).update(:weight => weight)
            m.reply "Weight set to: #{weight}kg", true
        rescue Exception => x
            m.reply "Error: #{x.message}"
        end
    end
    
    match /set gender (\S+)/, method: :set_gender
    def set_gender(m, gender)
        return unless ignore_nick(m.user.nick).nil?
        begin
            case gender
                when /^m(?:ale)?/i
                    sex = "Male"
                when /^f(?:emale)?/i
                    sex = "Female"
                else raise "Invalid gender"
            end
            Nick.first_or_create(:nick => m.user.nick.downcase).update(:gender => sex)
            m.reply "Gender set to: #{sex}", true
        rescue Exception => x
            m.reply "Error: #{x.message}"
        end
    end
  
    # Set metric preference
    
    match /set metric (true|false|on|off)/i, method: :set_metric
    def set_metric(m, preference)
        return unless ignore_nick(m.user.nick).nil?
        begin
            Nick.first_or_create(:nick => m.user.nick.downcase).update(:metric => to_bool(preference))
            m.reply "Metric preference set to: #{preference}", true
        rescue Exception => x
            m.reply "Error: #{x.message}"
        end
    end


    # Last.fm username

	match /set lastfm (.+)/i, method: :set_lastfm
	def set_lastfm(m, username)
		return unless ignore_nick(m.user.nick).nil?
		begin
			old = LastfmDB.first(:nick => m.user.nick.downcase)
			old.destroy! unless old.nil?

			new = LastfmDB.new(
				:nick => m.user.nick.downcase,
				:username => username.downcase
			)
			new.save

			m.reply "last.fm user updated to: #{username}", true
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end 


	# Weather location

	match /set location (.+)/i, method: :set_location
	def set_location(m, areacode)
		return unless ignore_nick(m.user.nick).nil?
		begin
			old = LocationDB.first(:nick => m.user.nick.downcase)
			old.destroy! unless old.nil?

			new = LocationDB.new(
				:nick => m.user.nick.downcase,
				:location => areacode.downcase
			)
			new.save

			m.reply "location updated to: #{areacode}", true
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end 

end