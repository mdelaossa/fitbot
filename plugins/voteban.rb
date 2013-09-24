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
            m.reply "VoteBan | #{@@defendant} Tally: Yes - #{@@yes} No - #{@@no}" unless @@defendant.nil?
        rescue Exception => e
        end
    end

	match /voteban (?!yes|no|cancel|threshold)(.+)/i, method: :voteban
	match /vb (?!yes|no|cancel|threshold)(.+)/i, method: :voteban
	def voteban(m, defendant)
		return unless ignore_nick(m.user.nick).nil?
		begin
		    raise 'Vote already in progress' unless @@defendant.nil?
		    
		    @@defendant = User(defendant)
		    @@starter = m.user
		    @@voters << @@starter
		    @@yes+=1
		    
		    @@timer.in '5m' do
		        cancel(m)
		    end
		    
			m.reply "VoteBan | #{defendant} | Vote started! Please vote on this ban with .vb yes|no"
		rescue Exception => e
			m.reply "VoteBan | Error: #{e}"
		end
	end
	
	match /vb (yes|no)/i, method: :vote
	def vote(m, vote)
	    return unless ignore_nick(m.user.nick).nil?
	    begin
	        raise "Can't vote twice" if @@voters.include? m.user
	        @@voters << m.user
            case vote
                when "yes"
                    @@yes += 1
                when "no"
                    @@no += 1
                else raise "That's not a valid vote. Yes or no only."
            end
            
            if @@yes >= @@threshold 
                m.channel.ban(@@defendant.mask("*!*@%h"));
		        m.channel.kick(@@defendant, "The people have spoken")
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
            
            m.reply "VoteBan | Vote added. #{@@defendant} Tally: Yes - #{@@yes} No - #{@@no}"
            
	    rescue Exception => e
	        m.reply "VoteBan | Error occured: #{e}", true
	    end
	end
end