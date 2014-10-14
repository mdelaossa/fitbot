require 'data_mapper'
require 'dm-migrations'
require 'dm-core'
require 'dm-postgres-adapter'
require 'do_postgres'
require 'dm-sqlite-adapter' if ENV['environment'] == 'development'

class Factoid
    include DataMapper::Resource
    
    property :name,         String,     :unique => true,  :key => true
    property :protect,      Boolean,    :default => false
    property :wildcard,     Boolean,    :default => false #wildcard matching
    
    has n, :factoid_values
    
    def self.wildcard
        all(:wildcard => true)
    end
end

class FactoidValue
    include DataMapper::Resource
    
    property :id,       Serial
    property :value,    String,     :length => 500
    property :addedBy,  String
end

class Nick
    include DataMapper::Resource
    
    property :id,       Serial
    property :nick,     String
    property :metric,   Boolean,    :default => true
    property :weight,   Float,      :default => 0
    property :height,   Float,      :default => 0
    property :gender,   String,     :default => "Male"
    
    has n, :lifts
end

class Lift
    include DataMapper::Resource
    
    property :id,       Serial
    property :lift,     String
    property :weight,   Float
    property :unit,     String,     :format => /kg|lb/, :default => lambda { |r, p|  if r.nick.metric then 'kg' else 'lb' end }
    property :reps,     Numeric,    :default => 1
    
    belongs_to :nick
end

class ReminderDB
    include DataMapper::Resource
    
    property(:id, Serial)
    property(:nick, String)
    property(:time, DateTime)
    property(:channel, String)
    property(:message, String)
    property(:network, String)
end

class Messages
    include DataMapper::Resource
    
    property(:id, Serial)
    property(:sender, String)
    property(:recipient, String)
    property(:sent_at, DateTime)
    property(:text, String)
    property(:channel, String)
    property(:network, String)
end

class LastfmDB 
    include DataMapper::Resource
	property(:id, Serial)
	property(:nick, String, :unique => true)
	property(:username, String)
end 

class IgnoreDB
	include DataMapper::Resource
	property(:id, Serial)
	property(:nick, String, :unique => true)
end 

class LocationDB 
	include DataMapper::Resource
	property(:id, Serial)
	property(:nick, String, :unique => true)
	property(:location, String)
end 

class AutoconvertDB
    include DataMapper::Resource
    property(:id, Serial)
    property(:channel, String, :unique => true)
end

class PassiveDB
	include DataMapper::Resource
	property(:id, Serial)
	property(:channel, String, :unique => true)
end 

class PassiveFDB
	include DataMapper::Resource
	property(:id, Serial)
	property(:channel, String, :unique => true)
end 

class JoinDB
	include DataMapper::Resource
	property(:id, Serial)
	property(:channel, String, :unique => true)
end 

class AdminDB
	include DataMapper::Resource
	property(:id, Serial)
	property(:nick, String, :unique => true)
end 

class InsultDB 
	include DataMapper::Resource
	property(:id, Serial)
	property(:insult, Text)
end 

class GreenText
	include DataMapper::Resource
	property(:id, Serial)
	property(:text, Text)
end 

class JobSubscription
    include DataMapper::Resource
    property(:id, Serial)
    property(:channel, String, :unique_index => :channel_network_index)
    property(:network, String, :unique_index => :channel_network_index)
end

DataMapper.finalize

#DataMapper.auto_migrate! #destructive
#DataMapper.auto_upgrade!