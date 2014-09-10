# encoding: utf-8

class Pick
    include Cinch::Plugin

	match /choose (.+)/i
	match /r(?:and)? (.+)/i
	def execute(m, query)
		return unless ignore_nick(m.user.nick).nil?

		begin
		    if query =~ /\|/
			    options = query.split(/\|/)
			elsif query =~ /,/
				options = query.split(/,/)
			else
			    options = query.split(/\sor\s/)
			end
			m.reply options[rand(options.length)], true
		rescue
			nil
		end
	end
end