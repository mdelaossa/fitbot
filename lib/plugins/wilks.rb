# encoding: utf-8

Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"

require 'mathn'

class Wilks
    include Cinch::Plugin
    include UtilityFunctions
    
    def get_wilks(gender, weight, total, scale, reverse = false)
        weight = weight.to_f
        total = total.to_f
        
    	if gender == "male"
			a=-216.0475144
			b=16.2606339
			c=-0.002388645
			d=-0.00113732
			e=0.00000701863
			f=-0.000000001291
		else
			a=594.31747775582
			b=-27.23842536447
			c=0.82112226871
			d=-0.00930733913
			e=0.00004731582
			f=-0.00000009054
		end

		weight = weight/2.2 if scale=="lbs"
		total = total/2.2 if scale=="lbs"

		if reverse
			total / (500/(a+b*weight+c*(weight**2)+d*(weight**3)+e*(weight**4)+f*(weight**5)))
		else
			total * (500/(a+b*weight+c*(weight**2)+d*(weight**3)+e*(weight**4)+f*(weight**5)))
		end
	end 
    
    match /wilks (\w+) (\d+(?:\.\d+)?) (\d+(?:\.\d+)?) (\w+)/iu, method: :wilks
    def wilks(m, gender, weight, liftingTotal, unit)
        ["female","woman","women"].include? gender ? gender = "female" : gender = "male"
        
        ["lbs","pounds","pound","p","l"].include? unit ? unit = "lbs" : unit = "kgs"
        
        reply = "Ratio: #{get_wilks(gender,weight,liftingTotal,unit)}"
        
        m.reply "Wilks | #{reply}"
    end
    
    match /rwilks (\w+) (\d+(?:\.\d+)?) (\d+(?:\.\d+)?) (\w+)/iu, method: :rwilks
    def rwilks(m, gender, weight, wilks, unit)
    
        ["female","woman","women"].include? gender ? gender = "female" : gender = "male"
        
        ["lbs","pounds","pound","p","l"].include? unit ? unit = "lbs" : unit = "kgs"
        
        reply = "Lifting total: #{get_wilks(gender,weight,wilks,unit,true)}"
        
        m.reply "Wilks | #{reply}"
    end
end