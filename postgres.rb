require 'data_mapper'
require 'dm-migrations'


DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://nwrbccnwejgxov:-QskzjvC5gQT4HW3QCtjtbFIf9@ec2-54-243-233-216.compute-1.amazonaws.com:5432/d6c661v9g22il')


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

DataMapper.finalize

#DataMapper.auto_migrate!
DataMapper.auto_upgrade!
