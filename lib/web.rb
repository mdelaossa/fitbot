require 'sinatra'
require 'sinatra/base'
class FitbotWeb
    
    def self.web
        @@web
    end
    
    def self.start
        @@web = Thread.new {
        
            my_app = Sinatra.new { 
                set :bind, ENV['IP'] unless ENV['IP'].nil? ##for c9.io support
                set :port, ENV['PORT'] unless ENV['PORT'].nil?
                
                ##routes
                get '/' do
                    erb :index 
                end
                
                get '/:name.json' do |name|
                    Nick.first(:nick => name.downcase).to_json(:only => [:nick, :weight, :height])
                end
                
                get '/lifts/:name.json' do |name|
                    Nick.first(:nick => name.downcase).lifts.to_json(:only => [:lift, :weight, :unit, :reps])
                end
                
                get '/lifts/?:name?' do |name|
                    erb :lifts, :locals => {:name => name}
                end
                ########
            }
            
            Thread.current[:web] = my_app
            
            my_app.run!
        }
    end
    
    def self.stop
        @@web.exit
    end
end