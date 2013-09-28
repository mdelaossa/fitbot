require 'rubygems'
require 'cinch'
require 'require_all'

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

# Plugins
require_all './plugins'
require "cinch/plugins/identify"

class Hash ##nicer accesors for hashmap values
    def method_missing(name, *args, &blk)
      if self.keys.map(&:to_sym).include? name.to_sym
        return self[name.to_sym]
      else
        return nil
      end
    end
end

def class_from_string(str) ##For loading modules from config
  str.split('::').inject(Object) do |mod, class_name|
    mod.const_get(class_name)
  end
end

# Global vars
$CONFIG        = YAML.load_file 'config.yml.testing'
$SHUTUP        = false


# Twitter Feed
$TWITTERFEED    = ""
$TWITTERCHANNEL = ""

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

def check_admin_kick(m)
    isAdmin = check_admin(m.user)
    m.channel.kick(m.user, "http://i.imgur.com/w7lGFWM.jpg") unless isAdmin
    isAdmin
end

@bots = []

Thread.new {
    require 'sinatra'
    require 'sinatra/base'
    my_app = Sinatra.new { 
        set :bind, ENV['IP']
        set :port, ENV['PORT']
        get('/') { "hi" } 
    }
    my_app.run!
}


$CONFIG.servers.each { |values|

    thread = Thread.new {
        bot = Cinch::Bot.new do
            configure do |c|
                c.server          = values.server
                c.port            = values.port
                c.ssl.use         = values.ssl.use
                c.ssl.verify      = values.ssl.verify
                c.nick            = values.nick
                c.realname        = values.realname
                c.user            = values.user
                c.password        = values.password
                c.modes           = values.modes || []
                c.channels        = values.channels || []
                c.plugins.prefix  = values.plugins.prefix
                c.plugins.plugins = values.plugins.plugins.collect { |plugin| class_from_string(plugin) } || []
                c.plugins.options[Cinch::Plugins::Identify] = {
                  :username => values.user,
                  :password => values.nickpass,
                  :type     => :nickserv
                }
            end
        end
        

        bot.start
    }
    
    @bots << thread
    
}

@bots.each {|thread| thread.join}