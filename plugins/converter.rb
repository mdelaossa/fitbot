# encoding: utf-8

Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"

require 'mathn'
require 'ruby-units'

class Converter
    include Cinch::Plugin
    
    listen_to :channel
    def listen(m)
        unless m.message =~ /^\.?convert/ || m.message =~ /^\.?r?wilks/
    		answer = {}
			#If the message includes pounds or kilograms
			if m.message =~ /\b(?:(?<!-)|(?=\.))(?:((?:\d+(?:,\d+)*)?(?:\.|,)?\d+)\s*\s*-\s*)?((?:\d+(?:,\d+)*)?(?:\.)?\d+)\s*((?:pound|kilo(?:\s*gram)?|lb|kg|#)s?)(?:\b|(?<=#))/i
				weights = m.message.scan(/\b(?:(?<!-)|(?=\.))(?:((?:\d+(?:,\d+)*)?(?:\.|,)?\d+)\s*\s*-\s*)?((?:\d+(?:,\d+)*)?(?:\.)?\d+)\s*((?:pound|kilo(?:\s*gram)?|lb|kg|#)s?)(?:\b|(?<=#))/i)
				answer[:weights]= Convert.parse_weights_from_channel(weights)
			end
			#When the message includes the word 'plate' (1 plate -> 135lb, 60kg)
			if m.message =~ /\b(?<!\.)(\d+|[a-z]+)-?\s?plates?/i
				plates = m.message.scan(/\b(?<!\.)(\d+|[a-z]+)-?\s?plates?/i)
				answer[:plates]= plates.map { |(num)|
					begin
						num = Numeral.parse_num(num)
						"#{num}-plate => #{Float(num)*(2*45)+45} lbs, #{Float(num)*(2*20)+20} kgs"
					rescue Exception
						# ignored
					end
				}.join(" | ")
			end
			#If m.message contains feet|inches
			if m.message =~ /\b(\d*\.?\d+)\s*(?:ft|feet)(?:\s*(\d+)\s*(?:in|inches))?\b|\b(\d*\.?\d+)(?:')(?:(\d+)(?:")?)?/i
				feet = m.message.scan /\b(\d*\.?\d+)\s*(?:ft|feet)(?:\s*(\d+)\s*(?:in|inches))?\b|\b(\d*\.?\d+)(?:')(?:(\d+)(?:")?)?/i
				answer[:feet]= feet.map { |a, b, c, d|
					begin
						a,b = c,d if (a.nil? and b.nil?)
						original = b.nil? ? "#{a}'" : "#{a}'#{b}\""
						ans = original.unit >> "meters"
						"#{original} => #{ans.scalar.to_f.round(3)} #{ans.units}"
					rescue Exception
						# ignored
					end
				}.join(" | ")
			end
			#If m.message contains meters
			if m.message =~ /\b(\d*\.?\d+)\s*m(?:eters?)?\b/i
				meters = m.message.scan /(\d*\.?\d+)\s*m(?:eters?)?\b/i
				answer[:meters]= meters.map { |(a)| #Why needs a ()?
					begin
						original = "#{a} m"
						"#{original} => #{original.unit.to_s(:ft)}"
					rescue Exception => e
						e.message
					end
				}.join(" | ")
			end
            #If m.message contains cm
            if m.message =~ /\b(\d*\.?\d+)\s*c(?:enti)?m(?:eters?)?\b/i
                centimeters = m.message.scan /\b(\d*\.?\d+)\s*c(?:enti)?m(?:eters?)?\b/i
    			answer[:centimeters]= centimeters.map { |(a)| #Why needs a ()?
					begin
						original = "#{a} cm"
						"#{original} => #{original.unit.to_s(:ft)}"
					rescue Exception => e
						e.message
					end
				}.join(" | ")
            end
            #If m.message contains stone
            if m.message =~ /\b(\d*\.?\d+)\s*stone\b/i
                stone = m.message.scan /\b(\d*\.?\d+)\s*stone\b/i
        		answer[:stone]= stone.map { |(a)| #Why needs a ()?
					begin
						original = "#{a} stone"
						"#{original} => #{original.unit.to_s(:ft)}"
					rescue Exception => e
						e.message
					end
				}.join(" | ")
            end
			m.reply answer.values.join(" | ")
		end
    end
    
    module Numeral
    	def self.parse_num(text)
			return nil unless text
			return nil if text.length == 0
			return parse_natural_num(text) if text[/[a-z|A-Z]/]
			numerator, denominator = text.split('/')
			return numerator.to_f if numerator.include?('.')
			return numerator.to_i if denominator.nil?
			denominator ||= 1
			Rational(numerator.to_i, denominator.to_i)
		end

		def self.parse_natural_num(text)
			%w(zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty).index(text.downcase)
		end
	end
    
    module Convert
    	def self.to_kg(num)
			(Float(num)/2.2).round(3)
		end

		def self.to_lb(num)
			(Float(num)*2.2).round(3)
		end

		def self.parse(expression)
			expression = expression.sub(/\bto\b/, "")
			case expression
				when /\s*(.+)?\s+(.+)/
					from = $1
					to = $2
					begin
						if to.unit.units == "ft"
							"#{from}".unit.to_s(:ft)
						else
							ans = "#{from}".unit >> "#{to}"
							"#{ans.scalar.to_f} #{ans.units}"
						end
					rescue Exception
						"Undefined conversion"
					end
				else
					"Undefined conversion"
			end
		end

		def self.parse_weights_from_channel(weights)
			weights.map { |a, b, unit| #|weight,index|

				a = a.gsub(/,/, "") unless a.nil?
				b = b.gsub(/,/, "")

				new_unit = (unit =~ /(?:pound|lb|#)s?/i) ? "kg" : "lb"
				unit = (new_unit == "kg") ? "lb" : "kg"

				case unit
					when "kg"
						new_a = Convert.to_lb a unless a.nil?
						new_b = Convert.to_lb b
					when "lb"
						new_a = Convert.to_kg a unless a.nil?
						new_b = Convert.to_kg b
					else
						# should never reach here
				end

				if a.nil?
					"#{b} #{unit} => #{new_b} #{new_unit}"
				else
					"#{a}-#{b} #{unit} => #{new_a}-#{new_b} #{new_unit}"
				end

			}.join(" | ")
		end
	end
end