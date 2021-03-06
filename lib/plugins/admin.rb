# encoding: utf-8

class Admin
    include Cinch::Plugin
    include UtilityFunctions

	set :prefix, lambda{ |m| /^#{m.bot.nick},?:?\s/i }

    match /op me/i, method: :opme
    def opme(m)
        return unless check_admin_kick(m)
        m.channel.op(m.user)
    end
    
    match /restart/, method: :restart
    def restart(m)
    	return unless check_admin_kick(m)
    	Fitbot.restart
    end
    
    match /op (?!me)(\S+)(?: (\S+))?/i, method: :op
    def op(m, who, channel)
        return unless check_admin_kick(m)
        who ||= m.user
        channel = Channel(channel) unless channel.nil?
        channel ||= m.channel
        channel.op(who)
    end
    
    match /deop (?!me)(\S+)(?: (\S+))?/i, method: :deop
    def deop(m, who, channel)
        return unless check_admin_kick(m)
        who ||= m.user
        channel = Channel(channel) unless channel.nil?
        channel ||= m.channel
        channel.deop(who)
    end
    
    match /voice (\S+)(?: (\S+))?/i, method: :voice
    def voice(m, who, channel)
        return unless check_admin_kick(m)
        who ||= m.user
        channel = Channel(channel) unless channel.nil?
        channel ||= m.channel
        channel.voice(who)
    end
    
    match /devoice (\S+)(?: (\S+))?/i, method: :devoice
    def devoice(m, who, channel)
        return unless check_admin_kick(m)
        who ||= m.user
        channel = Channel(channel) unless channel.nil?
        channel ||= m.channel
        channel.devoice(who)
    end
    
    match /raw (.+)/i, method: :raw
    def raw (m, command)
        return unless check_admin_kick(m)
        @bot.irc.send command
    end

	match /nick (.+)/i, method: :nick
	def nick(m, name)
		return unless check_admin_kick(m)
		@bot.nick = name
	end
	
    match /invite (\S+)(?: (\S+))?/i, method: :invite
    def invite(m, who, channel)
        return unless check_admin_kick(m)
        who ||= m.user
        channel = Channel(channel) unless channel.nil?
        channel ||= m.channel
        channel.invite(who)
    end

	match /quit(?: (.+))?/i, method: :quit
	def quit(m, msg)
		return unless check_admin_kick(m)
		msg ||= "brb"
		bot.quit(msg)
	end


	match /msg (.+?) (.+)/i, method: :message
	def message(m, who, text)
		return unless check_admin_kick(m)
		User(who).send text
	end


	match /say (.+?) (.+)/i, method: :message_channel
	def message_channel(m, chan, text)
		return unless check_admin_kick(m)
		Channel(chan).send text
	end
	
	match /do (.+?) (.+)/i, method: :action_channel
	def action_channel(m, chan, action)
	    return unless check_admin_kick(m)
	    Channel(chan).action action
	end


	match /kick (\S+)(:? (.+))?/i, method: :kick
	def kick(m, nick, reason)
		return unless check_admin_kick(m)
		reason ||= "Get out"
		m.channel.kick(nick, reason)
	end


	match /ban (\S+)(:? (.+))?/i, method: :ban
	def ban(m, nick, reason)
		return unless check_admin_kick(m)
		reason ||= "Get out"
		baddie = User(nick);
		m.channel.ban(baddie.mask("*!*@%h"));
		m.channel.kick(nick, reason)
	end



  # Ignore users

	match /ignore (.+)/i, method: :ignore
	def ignore(m, username)
		return unless check_admin_kick(m)

		begin
			old = IgnoreDB.first(:nick => username.downcase)
			old.destroy! unless old.nil?

			new = IgnoreDB.new(:nick => username.downcase)
			new.save

			m.reply "I never liked him anyway"
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end

	match /unignore (.+)/i, method: :unignore
	def unignore(m, username)
		return unless check_admin_kick(m)

		begin
			old = IgnoreDB.first(:nick => username.downcase)
			old.destroy! unless old.nil?

			m.reply "Sorry about that"
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end

	match /list ignores/i, method: :list_ignores
	def list_ignores(m)
		return unless check_admin_kick(m)
		begin
			agent = Mechanize.new
			rows = ""

			IgnoreDB.all.each do |item|
				rows = rows + item.id.to_s + ". " + item.nick + "\n"
			end

			page = agent.get "http://p.sjis.me/"
			form = page.forms.first
			form.content = rows
			page = agent.submit form

			m.reply page.search("//a[@name='plain']/@href").text, true
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end



  # Make/Remove admins

	match /add admin (.+)/i, method: :add_admin
	def add_admin(m, username)
		return unless $CONFIG.bot.owner.include? m.user.nick.downcase

		begin
			old = AdminDB.first(:nick => username.downcase)
			old.destroy! unless old.nil?

			new = AdminDB.new(:nick => username.downcase)
			new.save

			m.reply "A new master!"
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end

	match /remove admin (.+)/i, method: :del_admin
	def del_admin(m, username)
		return unless m.user.nick.to_s.downcase == $BOTOWNER || m.user.nick.downcase == $BOTOWNER2

		begin
			old = AdminDB.first(:nick => username.downcase)
			old.destroy! unless old.nil?

			m.reply "I never liked him anyway"
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end

	match /list admins/i, method: :list_admins
	def list_admins(m)
		return unless check_admin_kick(m)
		begin
        
            pastebin = Pastebin.new
			
			rows = ""
			AdminDB.all.each do |item|
				rows = rows + item.id.to_s + ". " + item.nick + "\n"
			end

			url = pastebin.paste(rows)

			m.reply url, true
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end



  # URI ON/OFF

	match /passive on(?: (.+))?/i, method: :passive_on
	def passive_on(m, channel)
		return unless check_admin_kick(m)
		channel ||= m.channel.to_s

		begin
			old = PassiveDB.first(:channel => channel.downcase)
			old.destroy! unless old.nil?

			m.reply "Now reacting to URIs"
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end

	match /passive off(?: (.+))?/i, method: :passive_off
	def passive_off(m, channel)
		return unless check_admin_kick(m)
		channel ||= m.channel.to_s

		begin
			old = PassiveDB.first(:channel => channel.downcase)
			old.destroy! unless old.nil?

			new = PassiveDB.new(:channel => channel.downcase)
			new.save

			m.reply "No longer reacting to URIs"
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end

	match /file info on(?: (.+))?/i, method: :passive_files_on
	def passive_files_on(m, channel)
		return unless check_admin_kick(m)
		channel ||= m.channel.to_s

		begin
			old = PassiveFDB.first(:channel => channel.downcase)
			old.destroy! unless old.nil?

			m.reply "Now reacting to file URIs"
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end

	match /file info off(?: (.+))?/i, method: :passive_files_off
	def passive_files_off(m, channel)
		return unless check_admin_kick(m)
		channel ||= m.channel.to_s

		begin
			old = PassiveFDB.first(:channel => channel.downcase)
			old.destroy! unless old.nil?

			new = PassiveFDB.new(:channel => channel.downcase)
			new.save

			m.reply "No longer reacting to file URIs"
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end



  # Join/Part channels

	match /join (.+)/i, method: :join
	def join(m, channel)
		return unless check_admin_kick(m)

		begin
			old = JoinDB.first(:channel => channel.downcase)
			old.destroy! unless old.nil?

			new = JoinDB.new(:channel => channel.downcase)
			new.save

			Channel(channel).join
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end

	match /part(?: (.+))?/i, method: :part
	def part(m, channel)
		return unless check_admin_kick(m)
		channel ||= m.channel.to_s

		begin
			old = JoinDB.first(:channel => channel.downcase)
			old.destroy! unless old.nil?

			Channel(channel).part if channel
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end

	match /list channels/i, method: :list_channels
	def list_channels(m)
		return unless check_admin_kick(m)
		begin
			pastebin = Pastebin.new
            
            rows = ""
			JoinDB.all.each do |item|
				rows = rows + item.id.to_s + ". " + item.channel + "\n"
			end

			url = pastebin.paste rows

			m.reply url, true
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end 



	# Last.fm 

	match /list lastfm/i, method: :list_lastfm
	def list_lastfm(m)
		return unless check_admin_kick(m)
		begin
			pastebin = Pastebin.new
			rows = ""

			LastfmDB.all.each do |item|
				rows = rows + item.id.to_s + ". " + item.nick + " = " + item.username + "\n"
			end

			url = pastebin.paste rows

    		m.reply url, true
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end 

	match /remove lastfm (\d+)/i, method: :del_lastfm
	def del_lastfm(m, number)
		return unless check_admin_kick(m)
		begin
			old = LastfmDB.first(:id => number.to_i)
			old.destroy! unless old.nil?

			m.reply "Done", true
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end



	# Locations 

	match /list locations/i, method: :list_locations
	def list_locations(m)
		return unless check_admin_kick(m)
		begin
			pastebin = Pastebin.new
			rows = ""

			LocationDB.all.each do |item|
				rows = rows + item.id.to_s + ". " + item.nick + " = " + item.location + "\n"
			end

			url = pastebin.paste rows

    		m.reply url, true
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end 

	match /remove location (\d+)/i, method: :del_location
	def del_location(m, number)
		return unless check_admin_kick(m)
		begin
			old = LocationDB.first(:id => number.to_i)
			old.destroy! unless old.nil?

			m.reply "Done", true
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end



	# Insults

	match /add insult (.+)/i, method: :add_insult
	def add_insult(m, text)
		return unless check_admin_kick(m)

		begin
			new = InsultDB.new(:insult => text)
			new.save

			m.reply "Added"
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end 

	match /remove insult (\d+)/i, method: :del_insult
	def del_insult(m, number)
		return unless check_admin_kick(m)
		begin
			old = InsultDB.first(:id => number.to_i)
			old.destroy! unless old.nil?

			m.reply "Done", true
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end

	match /list insults/i, method: :list_insults
	def list_insults(m)
		return unless check_admin_kick(m)
		begin
			pastebin = Pastebin.new
			rows = ""

			InsultDB.all.each do |item|
				rows = rows + item.id.to_s + ". " + item.insult + "\n"
			end

			url = pastebin.paste rows

    		m.reply url, true
		rescue
			m.reply "Oops something went wrong", true
			raise
		end
	end 

end