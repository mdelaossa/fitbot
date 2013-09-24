# encoding: utf-8

class VoteBan
    include Cinch::Plugin
    
    require 'rufus/scheduler'
    require 'chronic'
    
    @@timer = Rufus::Scheduler.start_new

    @@defendant = nil
    @@yes = 0
    @@no = 0
    @@threshold = 4
    @@starter = nil
    @@voters = []
    

    match /voteban cancel/i, method: :cancel
    match /vb cancel/i, method: :cancel
    def cancel(m)
        begin
            return unless ignore_nick(m.user.nick).nil?
            return unless check_admin_helper(m) || m.user == @@starter
            return if @@defendant.nil?
            nick = @@defendant
            @@defendant = nil
            @@yes = 0
            @@no = 0
            @@voters = []
            m.reply "VoteBan | Vote on #{nick} cancelled"
        rescue
            m.reply "VoteBan | No vote currently in progress"
        end
    end
    
    match /voteban threshold \d+/i, method: :threshold
    match /vb threshold \d+/i, method: :threshold
    def threshold(m, num)
        return unless check_admin_helper(m)
        @@threshold = num
        m.reply "VoteBan | Threshold changed to #{num}"
    end
    
    match /voteban$/i, method: :tally
    match /vb$/i, method: :tally
    def tally(m)
        begin
            m.reply "VoteBan | #{@@defendant} tally: Yes - #{@@yes} No - #{@@no}" unless @@defendant.nil?
        rescue Exception => e
        end
    end
    
    match /vote (yes|no)$/i, method: :vote
	def vote(m, vote)
	    return unless ignore_nick(m.user.nick).nil?
	    return if @@defendant.nil?
	    begin
	        raise "Can't vote twice" if @@voters.include? m.user.authname
	        raise "Only registered nicks can vote" if m.user.authname.nil?
	        @@voters << m.user.authname
            case vote
                when "yes"
                    @@yes += 1
                when "no"
                    @@no += 1
                else raise "That's not a valid vote. Yes or no only."
            end
            
            if @@yes >= @@threshold 
                m.channel.ban(@@defendant.mask("*!*@%h"))
		        m.channel.kick(@@defendant, "The people have spoken. 30 minute ban.")
		        @@timer.in '30m' do
		            m.channel.unban(@@defendant.mask("*!*@%h"))
		        end
		        @@defendant = nil
		        @@yes = 0
		        @@no = 0
		        @@voters = []
		        m.reply "VoteBan | Another win for democracy!"
            end
            
            if @@no >= @@threshold
                nick = @@defendant
                @@defendant = nil
		        @@yes = 0
		        @@no = 0
		        @@voters = []
		        m.reply "VoteBan | Vote failed. #{nick} got lucky this time." 
            end
            
            m.reply "VoteBan | Vote added. #{@@defendant} tally: Yes - #{@@yes} No - #{@@no}"
            
	    rescue Exception => e
	        m.reply "VoteBan | Error occured: #{e}", true
	    end
	end

	match /voteban (?!(?:cancel|threshold \d+)$)(.+)/i, method: :voteban
	match /vb (?!(?:cancel|threshold \d+)$)(.+)/i, method: :voteban
	def voteban(m, defendant)
		return unless ignore_nick(m.user.nick).nil?
		begin
		    user = User(defendant)
		    
		    raise 'Vote already in progress' unless @@defendant.nil?
		    raise "User not online" if user.nil?
		    raise "User not online" if user.host.nil?
		    raise "You can't ban that person!" if check_admin(user)
		    raise "Only registered nicks can vote" if m.user.authname.nil?
		    @@defendant = user
		    @@starter = m.user
		    @@voters << @@starter.authname
		    @@yes+=1
		    
		    @@timer.in '5m' do
		        cancel(m)
		    end
		    
			m.reply "VoteBan | #{defendant} | Vote started! Please vote on this ban with .vote yes|no"
		rescue Exception => e
			m.reply "VoteBan | Error: #{e}"
		end
	end
	
end