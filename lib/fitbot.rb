require 'bundler'
Bundler.require :default, :test

def class_from_string(str) ##For loading modules from config
  str.split('::').inject(Object) do |mod, class_name|
    mod.const_get(class_name)
  end
end

class Hash ##nicer accesors for hashmap values
    def method_missing(name, *args, &blk)
      if self.keys.map(&:to_sym).include? name.to_sym
        return self[name.to_sym]
      else
        return nil
      end
    end
end

class Fitbot
    require 'rubygems'
    require 'cinch'
    require 'require_all'
    
    # Database stuff
    require 'dm-core'
    require 'dm-postgres-adapter'
    require 'do_postgres'
    
    # Web stuff
    require './lib/web'
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
    require './lib/utility_functions'
    require_all './lib/plugins'
    require "cinch/plugins/identify"

    # Global vars
    $SHUTUP        = false
    
    
    # Twitter Feed
    $TWITTERFEED    = ""
    $TWITTERCHANNEL = ""
    
    def self.load_config(file='config.yml')
        $CONFIG        = YAML.load_file file
        require_relative './postgres.rb'
    end
    
    
    @@bots = []
    
    def self.bots
        @@bots
    end
    
    def self.start
        
        FitbotWeb.start
        
        @@bots.select!(&:alive?) ##Forget about dead threads
        
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
                
                Thread.current[:bot] = bot
    
                bot.start
            }
            
            @@bots << thread
        }
    end
    
    def self.restart
        self.stop
        self.start
    end
    
    def self.stop
        @@bots.each { |thread|
            thread[:bot].quit "Quitting"
        }
    end
    
    @@bots.each {|thread| thread.join}
    
end

trap('SIGTERM') do ##For some reason threads aren't stopping on heroku. Attempted fix
    Fitbot.stop
end

trap('SIGINT') do ##Clean break on CTRL+C
    Fitbot.stop
end