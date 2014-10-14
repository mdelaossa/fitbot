#encoding: UTF-8
class Jobs
  include Cinch::Plugin
  include UtilityFunctions
  
  require 'rufus/scheduler'
  require 'feedjira'
  
  @@timer = Rufus::Scheduler.start_new
  @@feed = nil #RSS feed
  @@feed_url = 'http://careers.stackoverflow.com/jobs/feed?allowsremote=True'
  @@last_job = nil #Holds the last job so we can tell when the feed is updated
  
  match /jobs(?:\s+(\d+))?/i, method: :get_jobs
  def get_jobs(m, number)
    number ||= 1
    number = number.to_i
    number = 4 if number > 4
    populate_feed() if @@feed.nil?
    
    reply = ""
    
    number.times do |time|
      job = @@feed.entries[time]
      reply += "✎| #{job.title} · #{job.url}\n"
    end
    
    m.reply reply, true
    
  end
  
  match /jobs\s+((?:un)?sub)/i, method: :subscribe
  def subscribe(m, action)
    begin
      case action
      when 'sub'
        JobSubscription.first_or_create(:channel => m.channel, :network => @bot.irc.network.name)
        m.reply "Channel subscribed to job updates"
      when 'unsub'
        JobSubscription.first(:channel => m.channel, :network => @bot.irc.network.name).destroy
        m.reply "Channel unsubscribed from job updates"
      end
    rescue => x
      m.reply "Job|Error|#{x.message}"
    end
  end
  
  def initialize(*args)
    super
    @@timer.every '5m', :first_in => '5s' do
        populate_feed()
    end
  end
  
  def populate_feed()
    @@feed ||= Feedjira::Feed.fetch_and_parse(@@feed_url)
    @@feed = Feedjira::Feed.update(@@feed)
    
    if @@feed.updated?
      new_job_notification
    end
  end
  
  def new_job_notification()
    message = ""
    @@feed.new_entries.each_with_index do |job, index|
      break if index >= 4
      message += "✎| #{job.title} · #{job.url}\n"
    end
    #TODO: send update to channels subscribed
    channels = JobSubscription.all(:network => @bot.irc.network.name)
    channels.each do |channel|
      Channel(channel).send message
    end
  end
  
end