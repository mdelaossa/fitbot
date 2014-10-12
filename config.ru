require './lib/fitbot'
Fitbot.load_config
Fitbot.db_connection
run Sinatra::Application
Fitbot.start