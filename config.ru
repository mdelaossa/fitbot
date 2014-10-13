require './lib/fitbot'
Fitbot.load_config
Fitbot.db_connection
Fitbot.start
Fitbot.web_load
run Sinatra::Application