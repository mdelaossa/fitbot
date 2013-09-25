require 'rubygems'
require 'cinch'

# Database stuff
require 'dm-core'
require 'dm-postgres-adapter'
require 'do_postgres'

# Web stuff
require 'mechanize'
require 'addressable/uri'
require 'uri'
require 'open-uri'
require 'nokogiri'
require 'openssl'

require 'date'
require 'time'
require 'cgi'

#Weather
require 'wunderground'

# Encoding issues
require 'iconv'

# Bitly API interfacing
require 'bitly'

# Global vars
$BOTNICK       = "rippletits" # Bot nick
$BOTPASSWORD   = "oiram" # Nickserv password
$BOTOWNER      = "sigma00" # Make sure this is lowercase
$BOTOWNER2     = "sigma"
$BOTURL        = "http://fitbot.codelogic.org" # Help page
$BOTGIT        = ""
$SHUTUP        = false

# Twitter Feed
$TWITTERFEED    = ""
$TWITTERCHANNEL = ""

# API Keys
$BINGAPI            = "0GBVYOgiIU+rMVqKXksWqYUh/Jok7KLazVwdxxuDXJA=" # For bing search and Translate plugins
$BITLYUSER          = "mdelaossa" # bitly username | Many plugins use this
$BITLYAPI           = "R_906dd9e81c9c7557989485f6e60fe64e" # bitly api key  |
$LASTFMAPI          = "026e348b23b3399d3c8574815cf05f6f" # For all last.fm functions
$WOLFRAMAPI         = "W2GVU5-XY7GQ69T55" # For Answers
$WUNDERGROUNDAPI    = "9f9be7b71f5b5b0e" #For Weather

require_relative './postgres.rb'

# Ignore list
def ignore_nick(user)
    check = IgnoreDB.first(:nick => user.downcase)
	check.nil? ? (return nil) : (return true)
end

# Passive on/off
def disable_passive(channel)
	check = PassiveDB.first(:channel => channel.downcase)
	check.nil? ? (return nil) : (return true)
end

# Passive on/off
def disable_passive_files(channel)
	check = PassiveFDB.first(:channel => channel.downcase)
	check.nil? ? (return nil) : (return true)
end

# Autoconvert on/off
def disable_autoconvert(channel)
    check = AutoconvertDB.first(:channel => channel.downcase)
    check.nil? ? (return nil) : (return true)
end

# Bot admins
def check_admin(user)
	user.refresh
    return false if user.authname.nil?
	@admins = AdminDB.first(:nick => user.authname.downcase)
end

def check_admin_helper(m)
    isAdmin = check_admin(m.user)
    m.channel.kick(m.user, "http://i.imgur.com/w7lGFWM.jpg") unless isAdmin
    isAdmin
end


# Basic plugins
require_relative './plugins/basic.rb'
require_relative './plugins/admin.rb'               # Admin
    
# Advacned plugins  
require_relative './plugins/userset.rb'             # UserSet
require_relative './plugins/urbandictionary.rb'     # UrbanDictionary
require_relative './plugins/weather.rb'             # Weather
require_relative './plugins/lastfm.rb'              # Lastfm
require_relative './plugins/uri.rb'                 # Uri
require_relative './plugins/translate.rb'           # Translate
require_relative './plugins/twitter.rb'             # Twitter
require_relative './plugins/insult.rb'              # Insult
require_relative './plugins/8ball.rb'               # Eightball
require_relative './plugins/rand.rb'                # Pick
require_relative './plugins/youtube.rb'             # Youtube
require_relative './plugins/bing.rb'                # Bing
require_relative './plugins/google.rb'              # Google
require_relative './plugins/answers.rb'             # Answers
require_relative './plugins/wilks.rb'               # Wilks
require_relative './plugins/converter.rb'           # Converter
require_relative './plugins/reminder.rb'            # Reminder
require_relative './plugins/lift_tracker.rb'        # LiftTracker
require_relative './plugins/factoid.rb'             # FactoidDB
require_relative './plugins/pastebin.rb'            # Pastebin
require_relative './plugins/isup.rb'                # IsUp
require_relative './plugins/voteban.rb'             # VoteBan
require_relative './plugins/voteban/ballot.rb'      # VoteBan

bot = Cinch::Bot.new do
  configure do |c|
    c.server            = "chat.freenode.net"
    c.port              = 6697
    c.ssl.use           = true
    c.ssl.verify        = false
    c.nick              = $BOTNICK
    c.realname          = $BOTNICK
    c.user              = $BOTNICK
    #c.verbose           = true
    c.channels          = ["##fitbot-control oiram",
                            "##fitbot",
                            "#fittit",
                            "#realfittit",
                            "##fitbot-test oiram"]
    c.plugins.prefix    = /^\./
    c.plugins.plugins   = [ Basic,
                            Admin,
                            UserSet,
                            UrbanDictionary,
                            Weather,
                            Lastfm,
                            Uri,
                            Translate,
                            Twitter,
                            Insult,
                            Eightball,
                            Pick,
                            Youtube,
                            Bing,
                            Google,
                            Answers,
                            Wilks,
                            Converter,
                            Reminder,
                            LiftTracker,
                            FactoidDB,
                            IsUp,
                            VoteBan]
  end
  
  on :join do |m|
    if m.user.nick =~ /qwebirc.+/
        m.user.msg "Hi there! Please change your nick with the command /nick NICKNAME. You will not be able to speak in the channel until you do. Thanks and welcome to #fittit", true
    end
  end

end

#bot.start #moved to bottom after new Thread



#SUBLUMINAL
Thread.new {
bot2 = Cinch::Bot.new do
  configure do |c|
    c.server            = "irc.subluminal.net"
    c.port              = 6667
    c.ssl.use           = false
    c.ssl.verify        = false
    c.nick              = "epsilon"
    c.realname          = "Sigma"
    c.user              = "epsilon"
    c.modes             = ["+B"]
    #c.verbose           = true
    c.channels          = ["#boats",
                            "#bots"]
    c.plugins.prefix    = /^\./
    c.plugins.plugins   = [ Basic,
                            Admin,
                            UserSet,
                            UrbanDictionary,
                            Weather,
                            Lastfm,
                            Uri,
                            Translate,
                            Twitter,
                            Insult,
                            Eightball,
                            Pick,
                            Youtube,
                            Bing,
                            Google,
                            Answers,
                            Wilks,
                            Converter,
                            Reminder,
                            LiftTracker,
                            FactoidDB,
                            IsUp,
                            VoteBan]
  end
  
end

bot2.start
}

#foonetic
Thread.new {
bot3 = Cinch::Bot.new do
  configure do |c|
    c.server            = "irc.foonetic.net"
    c.port              = 6697
    c.ssl.use           = true
    c.ssl.verify        = false
    c.nick              = "epsilon"
    c.realname          = "Sigma"
    c.user              = "epsilon"
    #c.verbose           = true
    c.modes             = ["+B"]
    c.channels          = ["#xkcd-pub"]
    c.plugins.prefix    = /^\./
    c.plugins.plugins   = [ Basic,
                            Admin,
                            UserSet,
                            UrbanDictionary,
                            Weather,
                            Lastfm,
                            Uri,
                            Translate,
                            Twitter,
                            Insult,
                            Eightball,
                            Pick,
                            Youtube,
                            Bing,
                            Google,
                            Answers,
                            Wilks,
                            Converter,
                            Reminder,
                            LiftTracker,
                            FactoidDB,
                            IsUp,
                            VoteBan]
  end
end
bot3.start
}

bot.start