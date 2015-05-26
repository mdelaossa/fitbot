class Ballot
    attr_accessor :timeout_job
    attr_reader :yes, :no, :defendant, :starter, :voters, :channel, :type
    
    def initialize ( defendant, starter, channel, type = :ban )
        @defendant = defendant
        @starter = starter
        @channel = channel
        @yes = 1
        @no = 0
        @voters = [@starter]
        @type = valid_type type
    end 
    
    def valid_types
        [:ban, :kick, :quiet]
    end
    
    def valid_type? type
        valid_types.include? type
    end
    
    def valid_type type
        valid_type?(type) ? type : :ban
    end
    
    def vote ( vote, user )
        raise "Can't vote twice" if @voters.include? user
        
        @voters << user
        
        case vote
            when "yes"
                @yes += 1
            when "no"
                @no += 1
            else raise "That's not a valid vote. Yes or no only."
        end
        
    end
    
    def tally
        "#{defendant} tally: Yes - #{yes} No - #{no}"
    end
    
    
end