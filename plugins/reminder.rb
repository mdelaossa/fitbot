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
        @@timer.in '30s' do
            loadFromDB()
        end
    end

    def loadFromDB()
        reminders = ReminderDB.all
        reminders.each do |reminder|
            if reminder[:time] < DateTime.now then
                debug "Reminder time passed, sending #{reminder}"
                @@timer.in '20s' do
                    User(reminder[:nick]).send "#{reminder[:message]} | [late is better than never!]"
                    reminder.destroy
                end
            else
                debug "Added reminder #{reminder}"
                @@timer.at reminder[:time] do
                    User(reminder[:nick]).send "#{reminder[:message]}"
                    reminder.destroy
                end
            end
        end
    end
    
end