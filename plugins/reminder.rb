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
                m.reply "Reminder 2| Wrong time. Remember, NATURAL LANGUAGE (ex. 'in two minutes', '5 hours from now', 'next friday').", true
                return
            end
            
            reminder = ReminderDB.create( :nick => m.user.nick.downcase, :time => realtime, :message => message, :channel => m.channel )
            
            @@timer.at realtime do
                reminder.destroy
                m.reply message, true
            end

			m.reply "Reminder 2| Will be reminded at #{realtime}: #{message}", true
		rescue Exception => x
            error x.message
            error x.backtrace.inspect
			m.reply "Reminder 2| Error", true
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
                Channel(reminder[:channel]).send "#{reminder[:nick]}: #{reminder[:message]}"
            end
        end
    end
    
end