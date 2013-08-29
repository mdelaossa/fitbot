# encoding: utf-8

class Pick
    include Cinch::Plugin

	match /r(?:and)? (.+)/i
	def execute(m, query)
		return unless ignore_nick(m.user.nick).nil?

		begin
		    if query =~ /\|/
			    options = query.split(/\|/)
			    m.reply options[rand(options.length)], true
			else
			    options = query.split(/or/)
			    m.reply options[rand(options.length)], true
			end
		rescue
			nil
		end
	end
end