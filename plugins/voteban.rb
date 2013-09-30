# encoding: utf-8

class VoteBan
    include Cinch::Plugin
    
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

    match /voteban registered/, method: :registered
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

    match /voteban cancel/i, method: :cancel
    match /vb cancel/i, method: :cancel
    def cancel(m)
        begin
            return unless ignore_nick(m.user.nick).nil?
            ballot = find_ballot(m.channel)
            raise 'No vote in progress' if ballot.nil?
            raise 'Only the starter or an admin can cancel' unless check_admin(m.user) || m.user == ballot.starter
            
            @ballots.delete ballot
            ballot.timeout_job.unschedule

            m.reply "VoteBan | Vote on #{ballot.defendant} cancelled"
        rescue Exception => e
            m.reply "VoteBan | Error: #{e}"
        end
    end
    
    match /voteban threshold \d+/i, method: :threshold
    match /vb threshold \d+/i, method: :threshold
    def threshold(m, num)
        return unless check_admin_kick(m)
        @threshold = num
        m.reply "VoteBan | Threshold changed to #{num}"
    end
    
    match /voteban$/i, method: :tally
    match /vb$/i, method: :tally
    def tally(m)
        begin
            ballot = find_ballot(m.channel)
            raise 'No vote in progress' if ballot.nil?
            m.reply "VoteBan | #{ballot.tally}"
        rescue Exception => e
            m.reply "VoteBan | Error: #{e}"
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
                m.channel.ban(ballot.defendant.mask("*!*@%h"))
		        m.channel.kick(ballot.defendant, "The people have spoken. 30 minute ban.")
		        @@timer.in '30m' do
		            m.channel.unban(ballot.defendant.mask("*!*@%h"))
		        end
		        @ballots.delete ballot ##end ballot
		        ballot.timeout_job.unschedule
		        m.reply "VoteBan | Another win for democracy!"
		        return
            end
            
            if ballot.no >= @threshold
                @ballots.delete ballot ##end ballot
                ballot.timeout_job.unschedule
		        m.reply "VoteBan | Vote failed. #{ballot.defendant} got lucky this time." 
		        return
            end
            
            m.reply "VoteBan | Vote added. #{ballot.tally}"
            
	    rescue Exception => e
	        m.reply "VoteBan | Error occured: #{e}", true
	    end
	end

	match /voteban (?!(?:registered|cancel|threshold \d+)$)(.+)/i, method: :voteban
	match /vb (?!(?:registered|cancel|threshold \d+)$)(.+)/i, method: :voteban
	def voteban(m, defendant)
		return unless ignore_nick(m.user.nick).nil?
		begin
		    defendant = User(defendant)
		    
		    raise 'Vote already in progress' unless find_ballot(m.channel).nil?
		    raise "User not online" if defendant.nil?
		    raise "User not online" if defendant.host.nil?
		    raise "You can't ban that person!" if check_admin(defendant)
		    raise "Only registered nicks can vote" if m.user.authname.nil? and @registered
		    
		    ballot = Ballot.new(defendant, m.user, m.channel)
		    @ballots << ballot
		    
		    ballot.timeout_job = @@timer.schedule_in '5m' do
		        cancel(m)
		    end
		    
			m.reply "VoteBan | #{defendant} | Vote started! Please vote on this ban with .vote yes|no"
		rescue Exception => e
			m.reply "VoteBan | Error: #{e}"
		end
	end
	
end