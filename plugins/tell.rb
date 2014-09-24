# encoding: utf-8
class Tell
  include Cinch::Plugin
  
  def relative_time(start_time)
    diff_seconds = Time.now - start_time
    case diff_seconds
      when 0 .. 59
        return "#{diff_seconds.round(2)} seconds ago"
      when 60 .. (3600-1)
        return "#{(diff_seconds/60).round(2)} minutes ago"
      when 3600 .. (3600*24-1)
        return "#{(diff_seconds/3600).round(2)} hours ago"
      when (3600*24) .. (3600*24*30) 
        return "#{(diff_seconds/(3600*24)).round(2)} days ago"
      else
        return start_time.strftime("on %m/%d/%Y")
    end
  end
  
  listen_to :channel
  
  match /tell\s+(\w+)\s+(.+$)/i
  
  def execute(m, recipient, message)
    begin
      outbox = Messages.create(:sender => m.user.nick, :recipient => recipient, :sent_at => Time.now, :text => message, :channel => m.channel, :network => @bot.irc.network.name)
      if outbox.nil?
        error outbox
        m.reply "Tell | Error creating message", true
      else
        debug "created Tell message:"
        debug outbox.inspect
        m.reply "Tell | Message created successfully", true
      end
    rescue => x
      error x.message
      error x.backtrace.inspect
			m.reply "Tell | Error creating message"
    end
  end
  
  def listen(m)
    message = Messages.first :recipient => m.user.nick, :channel => m.channel, :network => @bot.irc.network.name
    if !message.nil?
      formatted_message = "✉ | #{message.text} · from #{message.sender} · #{relative_time(message.sent_at.to_time)}"
      message.destroy
      m.reply(formatted_message, true)
    end
  end
  
end
