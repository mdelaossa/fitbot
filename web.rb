require 'sinatra'
require 'sinatra/base'
Thread.new {
    my_app = Sinatra.new { 
        set :bind, ENV['IP'] unless ENV['IP'].nil? ##for c9.io support
        set :port, ENV['PORT'] unless ENV['PORT'].nil?
        
        ##routes
        get '/' do
            erb :index 
        end
        
        get '/lifts/?:name?' do |name|
            erb :lifts, :locals => {:name => name}
        end
        ########
    }
    my_app.run!
}