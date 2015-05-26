# encoding: utf-8

class Voting
    include Cinch::Plugin
    include UtilityFunctions
    
    require 'rufus/scheduler'
    
    @@timer = Rufus::Scheduler.start_new
    
    def initialize(*args)
        super *args
        @ballots = []
        @registered = true
        @threshold = 4
    end

    def find_ballot(channel)
        @ballots.find { |ballot| ballot.channel == channel}
    end

    match /voting registered/, method: :registered
    def registered(m)
        return unless ignore_nick(m.user.nick).nil?
        return unless check_admin_kick(m)
        if @registered
            @registered = false
            m.reply "Registration not required anymore"
        else
            @registered = true
            m.reply "Registration now required"
        end
    end

    match /voting cancel/i, method: :cancel
    def cancel(m)
        begin
            return unless ignore_nick(m.user.nick).nil?
            ballot = find_ballot(m.channel)
            raise 'No vote in progress' if ballot.nil?
            raise 'Only the starter or an admin can cancel' unless check_admin(m.user) || m.user == ballot.starter
            
            @ballots.delete ballot
            ballot.timeout_job.unschedule

            m.reply "Voting | Vote on #{ballot.defendant} cancelled"
        rescue Exception => e
            m.reply "Voting | Error: #{e}"
        end
    end
    
    match /voting threshold (\d+)/i, method: :threshold
    def threshold(m, num)
        return unless check_admin_kick(m)
        @threshold = num
        m.reply "Voting | Threshold changed to #{num}"
    end
    
    match /voting$/i, method: :tally
    def tally(m)
        begin
            ballot = find_ballot(m.channel)
            raise 'No vote in progress' if ballot.nil?
            m.reply "Voting | #{ballot.tally}"
        rescue Exception => e
            m.reply "Voting | Error: #{e}"
        end
    end
    
    match /vote (yes|no)$/i, method: :vote
	def vote(m, vote)
	    return unless ignore_nick(m.user.nick).nil?
	    begin
	        raise "Only registered nicks can vote" if m.user.authname.nil? and @registered
	        
	        ballot = find_ballot(m.channel)
	        raise "No vote in progress" if ballot.nil?

            ballot.vote vote, m.user 
            
            if ballot.yes >= @threshold 
                case ballot.type
                when :ban
                    m.channel.ban(ballot.defendant.mask("*!*@%h"))
		            m.channel.kick(ballot.defendant, "The people have spoken. 30 minute ban.")
		            @@timer.in '30m' do
		                m.channel.unban(ballot.defendant.mask("*!*@%h"))
		            end
		        when :kick
		            m.channel.kick(ballot.defendant, "Buh bye")
		        when :quiet
		            m.channel.mode("+q #{ballot.defendant.mask("*!*@%h")}")
		            m.channel.send("Quieted for 30 minutes")
		            @@timer.in '30m' do
		                m.channel.mode("-q #{ballot.defendant.mask("*!*@%h")}")
		            end
		        end
		        
		        @ballots.delete ballot ##end ballot
		        ballot.timeout_job.unschedule
		        m.reply "Voting | Another win for democracy!"
		        return
            end
            
            if ballot.no >= @threshold
                @ballots.delete ballot ##end ballot
                ballot.timeout_job.unschedule
		        m.reply "Voting | Vote failed. #{ballot.defendant} got lucky this time." 
		        return
            end
            
            m.reply "Voting | Vote added. #{ballot.tally}"
            
	    rescue Exception => e
	        m.reply "Voting | Error occured: #{e}", true
	    end
	end

	match /voteban (.+)/i, method: :voteban
	match /vb (.+)/i, method: :voteban
	def voteban(m, defendant)
		start_vote(m, defendant, :ban)
	end
	
	match /votekick (.+)/i, method: :votekick
	match /vk (.+)/i, method: :votekick
	def votekick(m, defendant)
	    start_vote(m, defendant, :kick)
	end
	
	match /votequiet (.+)/i, method: :votequiet
	match /vq (.+)/i, method: :votequiet
	def votequiet(m, defendant)
	    start_vote(m, defendant, :quiet)
	end
	
	def start_vote(m, defendant, type)
	    return unless ignore_nick(m.user.nick).nil?
		begin
		    defendant = User(defendant)
		    
    	    raise 'Vote already in progress' unless find_ballot(m.channel).nil?
    	    raise "User not online" if defendant.nil?
    	    raise "User not online" if defendant.host.nil?
    	    raise "You can't #{type} that person!" if check_admin(defendant)
    	    raise "Only registered nicks can vote" if m.user.authname.nil? and @registered
    	    
    	    ballot = Ballot.new(defendant, m.user, m.channel, type)
    	    @ballots << ballot
    	    
    	    ballot.timeout_job = @@timer.schedule_in '5m' do
    	        cancel(m)
    	    end
    	    
    	    m.reply "Voting | #{defendant} | Vote started! Please vote on this #{type} with .vote yes|no"
		rescue Exception => e
			m.reply "Voting | Error: #{e}"
		end
	end
	
end