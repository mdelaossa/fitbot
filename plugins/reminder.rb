# encoding: utf-8

class Reminder
    include Cinch::Plugin
    
    require 'rufus/scheduler'
    require 'chronic'
    
    @@timer = Rufus::Scheduler.start_new
    
    match /(?:remind|timer) (.+)\s?\|\s?(.+)/i
    
    def execute (m,time,message)
        return unless ignore_nick(m.user.nick).nil?
    	begin
        
            realtime = Chronic.parse time
            
            if realtime.nil?
                m.reply "Reminder 2| Wrong time. Remember, NATURAL TIME (ex. 'in two minutes', '5 hours from now').", true
                return
            end
            
            @@timer.at realtime do
              m.reply message, true
            end

			m.reply "Reminder 2| Will be reminded #{realtime}: #{message}", true
		rescue
			m.reply "Reminder 2| Error", true
		end
    end
    
end