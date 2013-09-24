# encoding: utf-8

class VoteBan
    include Cinch::Plugin

    @defendant = nil
    @yes = 0
    @no = 0
    @threshold = 4

	match /voteban (.+)/i, method: :voteban
	match /vb (?!yes|no)(.+)/i, method: :voteban
	def voteban(m, defendant)
		return unless ignore_nick(m.user.nick).nil?
		begin
		    raise 'Vote already in progress' if not @defendant.nil?
		    @defendant = User(defendant)
		    @yes++
			m.reply "VoteBan | #{defendant} | Vote started! Please vote on this ban with .vb yes|no"
		rescue Exception => e
			m.reply "VoteBan | Error: #{e}"
		end
	end
	
	match /vb (yes|no)/i, method: :vote
	def vote(m, vote)
	    return unless ignore_nick(m.user.nick).nil?
	    begin
            case vote
            when 'yes'
                @yes++
            when 'no'
                @no++
            else raise "That's not a valid vote. Yes or no only."
            end
            
            if @yes >= @threshold 
                m.channel.ban(@defendant.mask("*!*@%h"));
		        m.channel.kick(@defendant, "The people have spoken")
		        @defendant = nil
		        @yes = 0
		        @no = 0
		        m.reply "VoteBan | Another win for democracy!"
            end
            
            if @no >= @threshold
                nick = @defendant
                @defendant = nil
		        @yes = 0
		        @no = 0
		        m.reply "VoteBan | Vote failed. #{nick} got lucky this time." 
            end
            
            m.reply "VoteBan | Vote added. Tally: Yes - #{@yes} No - #{@no}"
            
	    rescue Exception => e
	        m.reply "VoteBan | Error occured: #{e}", true
	    end
	end
end