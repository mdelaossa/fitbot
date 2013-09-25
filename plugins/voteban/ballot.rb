class Ballot

    attr_reader :yes, :no, :defendant, :starter, :voters, :channel
    
    def initialize ( defendant, starter, channel )
        @defendant = defendant
        @starter = starter
        @channel = channel
        @yes = 1
        @no = 0
        @voters = [@starter]
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