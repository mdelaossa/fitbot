# encoding: utf-8

class Reminder
    include Cinch::Plugin
    
    require 'rufus/scheduler'
    require 'chronic'
    
    @@timer = Rufus::Scheduler.start_new
    
    match /(?:remind(?:me)?|timer) (.+?)(?:(?:\s?\|\s?)| to | that )(.+)/i
    
    def execute (m,time,message)
        return unless ignore_nick(m.user.nick).nil?
    	begin
        
            realtime = Chronic.parse time
            
            if realtime.nil?
                m.user.send "Reminder | Wrong time. Remember, NATURAL LANGUAGE (ex. 'in two minutes', '5 hours from now', 'next friday')."
                return
            end
            
            reminder = ReminderDB.create( :nick => m.user.nick.downcase, :time => realtime, :message => message, :channel => m.channel )
            
            @@timer.at realtime do
                reminder.destroy
                m.user.send message
            end

			m.user.send "Reminder | Will be reminded at #{realtime}: #{message}"
		rescue Exception => x
            error x.message
            error x.backtrace.inspect
			m.user.send "Reminder | Error"
		end
    end
    
    def initialize(*args)
        super
        loadFromDB()
    end
    
    def loadFromDB()
        reminders = ReminderDB.all
        reminders.each do |reminder|
            debug "Added reminder #{reminder}"
            @@timer.at reminder[:time] do
                reminder.destroy
                User(reminder[:nick]).send "#{reminder[:message]}"
            end
        end
    end
    
end