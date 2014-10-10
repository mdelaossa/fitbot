require './lib/fitbot'
Fitbot.load_config
Fitbot.db_connection
Fitbot.start
run Sinatra::Application