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
  
  match /tell\s+(\S+)\s+(.+$)/i, method: :execute
  match /inbox$/i, method: :pmAllMessages
  
  def execute(m, recipient, message)
    begin
      outbox = Messages.create(:sender => m.user.nick, :recipient => recipient.downcase, :sent_at => Time.now, :text => message, :channel => m.channel, :network => @bot.irc.network.name)
      if outbox.nil?
        error "Error creating message:"
        error outbox
        m.user.send "Tell | Error creating message"
      else
        debug "created Tell message:"
        debug outbox.inspect
        m.user.send "Tell | Message created successfully: user=#{recipient}, message=#{message}"
      end
    rescue => x
      error x.message
      error x.backtrace.inspect
			m.user.send "Tell | Error creating message"
    end
  end
  
  def listen(m)
    unless m.message =~ /^.inbox$/ #don't show a message in channel if 
      messages = Messages.all :recipient => m.user.nick.downcase, :channel => m.channel, :network => @bot.irc.network.name
      if !messages.empty?
        formatted_message = "✉ | #{messages[0].text} · from #{messages[0].sender} · #{relative_time(messages[0].sent_at.to_time)}"
        formatted_message += " · Reimaining: #{messages.size - 1}" if messages.size > 1
        messages[0].destroy
        m.reply(formatted_message, true)
      end
    end
  end
  
  def pmAllMessages(m)
    messages = Messages.all :recipient => m.user.nick.downcase, :network => @bot.irc.network.name
    header = "✉ | Messages: #{messages.size}"
    header += " · showing first 5 only" if messages.size > 5
    m.user.send header
    messages[0..4].each do |message|
      formatted_message = "✉ | #{message.text} · from #{message.sender} · channel #{message.channel} · #{relative_time(message.sent_at.to_time)}"
      message.destroy
      m.user.send formatted_message
    end
  end
  
end
