require 'data_mapper'
require 'dm-migrations'


DBFILE = "./sqlite.db"
DataMapper.setup(:default, "sqlite3://" + DBFILE)


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

# If database doesn't exist, create. Else update
if(!File.exists?(DBFILE))
	DataMapper.auto_migrate!
elsif(File.exists?(DBFILE))
	DataMapper.auto_upgrade!
end