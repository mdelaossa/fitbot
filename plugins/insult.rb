# encoding: utf-8

class Insult
    include Cinch::Plugin

	match /insult(?: (.+))?/i

	def execute(m, faggot)
		return unless ignore_nick(m.user.nick).nil?
		faggot ||= m.user.nick

		retrys = 2

		begin
			randomInsult = InsultDB.get(1+rand(InsultDB.count))
			m.reply "%s: %s" % [faggot, randomInsult.insult]
		rescue
			if retrys > 0
				retrys = retrys - 1
				retry
			else
				m.reply "#{faggot}: I consider you one of the LOVELIEST women on IRC. Once you’ve been selected you must choose 15 of the most BEAUTIFUL women on your friends list. If you are awarded this distinction more than once, then you will know that you are EXCEPTIONALLY beautiful! Cut and paste this to 15 Beautiful women you know"
			end
		end
	end

end