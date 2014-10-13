require 'sinatra'
require 'sinatra/base'

    
    set :bind, ENV['IP'] unless ENV['IP'].nil? ##for c9.io support
    set :port, ENV['PORT'] unless ENV['PORT'].nil?
    
    ##routes
    get '/' do
        erb :index 
    end
    
    get '/:name.json' do |name|
        Nick.first(:nick => name.downcase).to_json(:only => [:nick, :weight, :height, :gender])
    end
    
    get '/lifts/:name.json' do |name|
        Nick.first(:nick => name.downcase).lifts.to_json(:only => [:lift, :weight, :unit, :reps])
    end
    
    get '/lifts/?:name?' do |name|
        erb :lifts, :locals => {:name => name}
    end
    ########
