# encoding: utf-8

class FactoidDB
    include Cinch::Plugin
    
    $PROTECT = false
    
    def protect(user)
        return false if check_admin(user)
        return $PROTECT
    end
    
    def shutup(user)
        return false if check_admin(user)
        return $SHUTUP
    end
    
    listen_to :channel
    def listen(m)
        unless m.message =~ /^\./ || $SHUTUP
            return unless ignore_nick(m.user.nick).nil?
            begin
            	            
                factoid = Factoid.first :name => m.message.downcase
                if !factoid.nil?
                    m.reply "#{factoid.factoid_values.all.sample.value}", false
                else
                    Factoid.wildcard.all.each { |x| 
                        if m.message.downcase =~ /\b#{x.name}\b/
                            m.reply "#{x.factoid_values.all.sample.value}", false
                        end
                    }
                end
        	rescue Exception => x
                error x.message
                error x.backtrace.inspect
    			#m.reply "FactoidDB | Error | #{x.message}"
    		end
        end
    end
    
    match /factoid list/i, method: :listFactoids
    def listFactoids(m)
        return unless check_admin(m.user)
        begin
            pastebin = Pastebin.new
    		rows = ""

			Factoid.all.each do |item|
				rows = rows + item.name + "\n"
			end

			url = pastebin.paste rows

    		m.reply url, true
        rescue Exception => x
            error x.message
            error x.backtrace.inspect
    		m.reply "FactoidDB | Error | #{x.message}"
        end
    end
    
    match /factoid (on|off|gprotect|nprotect)/i, method: :quiet
    def quiet(m, quiet)
        return unless check_admin(m.user)
        case quiet
        when /off/i
            $SHUTUP = true
            m.reply "FactoidDB | Automatic replies turned off"
        when /on/i
            $SHUTUP = false
            m.reply "FactoidDB | Automatic replies turned on"
        when /gprotect/i
            $PROTECT = true
            m.reply "FactoidDB | Only admins can add factoids"
        when /nprotect/i
            $PROTECT = false
            m.reply "FactoidDB | Everyone can add factoids"
        end
    end
    
    match /get all (.+)$/i, method: :getAllFactoid
    match /fact(?:oid)? get all (.+)$/i, method: :getAllFactoid
    def getAllFactoid(m, name)
    return unless ignore_nick(m.user.nick).nil?
    return unless !protect(m.user) and !shutup(m.user)
        begin
        	            
            factoid = Factoid.first :name => name.downcase
            if factoid.nil?
                m.reply "FactoidDB | No factoid found for key '#{name.downcase}'", true
            else        
                values = []
                factoid.factoid_values.all(:fields=>[:value]).each { |val| values << val.value }
                vals = values.join(" || ")
                if vals.length > 400
                    pastebin = Pastebin.new
                    url = pastebin.paste values.join ("\n")
                    m.reply "| FactoidDB | #{factoid.name} | Values: #{url}", true
                else
                    m.reply "FactoidDB | #{factoid.name} | #{vals}", true
                end
                debug factoid.factoid_values.all(:fields=>[:value]).inspect
            end
    	rescue Exception => x
            error x.message
            error x.backtrace.inspect
			m.reply "FactoidDB | Error | #{x.message}"
		end
    end
    
    match /get (.+?) \/(.+)\/$/i,method: :getSpecificFactoid
    match /fact(?:oid)? get (.+?) \/(.+)\/$/i,method: :getSpecificFactoid
    def getSpecificFactoid(m, name, regex)
        return unless ignore_nick(m.user.nick).nil?
        return unless !protect(m.user) and !shutup(m.user)
        begin
        	            
            factoid = Factoid.first :name => name.downcase
            if factoid.nil?
                m.reply "FactoidDB | No factoid found for key '#{name.downcase}'", true
            else        
                ans = factoid.factoid_values.first(:value.like => "%#{regex}%")
                if ans.nil?
                    m.reply "FactoidDB | No factoid found containing '#{regex}' in key '#{name.downcase}'"
                else
                    m.reply "FactoidDB | #{factoid.name} | #{ans.value}", true
                end
            end
    	rescue Exception => x
            error x.message
            error x.backtrace.inspect
			m.reply "FactoidDB | Error | #{x.message}"
		end
    end
    
    match /get (?!all)(.+?[^\/])$/i, method: :getFactoid
    match /fact(?:oid)? get (?!all)(.+?[^\/])$/i, method: :getFactoid
    def getFactoid(m, name)
        return unless ignore_nick(m.user.nick).nil?
        return unless !protect(m.user) and !shutup(m.user)
        begin
    		            
            factoid = Factoid.first :name => name.downcase
            if factoid.nil?
                m.reply "FactoidDB | No factoid found for key '#{name.downcase}'", true
            else        
                m.reply "FactoidDB | #{factoid.name} | #{factoid.factoid_values.all.sample.value}", true
            end
    	rescue Exception => x
            error x.message
            error x.backtrace.inspect
			m.reply "FactoidDB | Error | #{x.message}"
		end
    end
    
    match /fact(?:oid)? wild(?:card)? (.+?)\s*\|\s*(.+)$/i, method: :addWildcardFactoid
    def addWildcardFactoid(m, name, value)
        return unless ignore_nick(m.user.nick).nil?
        return unless !protect(m.user) and !shutup(m.user)
        begin
            name = name.downcase
            factoid = Factoid.first :name => name
            factoid ||= Factoid.create :name => name, :wildcard => true
            if factoid.protect
                if not check_admin(m.user)
                    m.reply "FactoidDB | Can't add to '#{factoid.name}': factoid protected"
                    return
                end
            end
            factoid.update :wildcard => true
            val = factoid.factoid_values.first_or_create({ :value => value }, { :addedBy => getAuthOrNick(m.user) })
            m.reply "FactoidDB | Added: '#{name}' => '#{value}'"
            debug val.inspect
        rescue Exception => x
            error x.message
            error x.backtrace.inspect
            m.reply "FactoidDB | Error | #{x.message}"
        end
    end
    
    match /fact(?:oid)? add (.+?)\s*\|\s*(.+)$/i, method: :addFactoid
    def addFactoid(m, name, value)
        return unless ignore_nick(m.user.nick).nil?
        return unless !protect(m.user) and !shutup(m.user)
        begin
            name = name.downcase
            factoid = Factoid.first_or_create :name => name
            if factoid.protect
                    if not check_admin(m.user)
                        m.reply "FactoidDB | Can't add to '#{factoid.name}': factoid protected"
                        return
                    end
                end
            val = factoid.factoid_values.first_or_create({ :value => value }, { :addedBy => getAuthOrNick(m.user) })
            m.reply "FactoidDB | Added: '#{name}' => '#{value}'"
            debug val.inspect
        rescue Exception => x
            error x.message
            error x.backtrace.inspect
            m.reply "FactoidDB | Error | #{x.message}"
        end
    end
    
    match /fact(?:oid)? wildcard (on|off) (.+)/i, method: :toggleWildcard
    def toggleWildcard(m, name)
        return unless ignore_nick(m.user.nick).nil?
        begin
            factoid = Factoid.first :name => name.downcase
            raise "Factoid does not exist" if factoid.nil?
            factoid.wildcard = factoid.wildcard == true ? false : true
            factoid.save
            m.reply "FactoidDB | Toggled wildcard for factoid #{factoid.name}"
        rescue Exception => x
            error x.message
            error x.backtrace.inspect
            m.reply "FactoidDB | Error | #{x.message}"
        end
    end
    
    def getAuthOrNick(user)
        if user.authname.nil?
            return user.nick
        else
            return user.authname
        end
    end
    
    match /fact(?:oid)? protect (.+)/i, method: :protectFactoid
    def protectFactoid(m, name)
        return unless ignore_nick(m.user.nick).nil?
        return unless check_admin(m.user)
        begin
            factoid = Factoid.first :name => name.downcase
            if factoid.nil?
                raise "Factoid does not exist"
            else
                factoid.protect = true
                factoid.save
                m.reply "FactoidDB | Protected factoid '#{factoid.name}'"
            end
        rescue Exception => x
            error x.message
            error x.backtrace.inspect
            m.reply "FactoidDB | Error | #{x.message}"
        end
    end
    
match /fact(?:oid)? unprotect (.+)/i, method: :unprotectFactoid
    def unprotectFactoid(m, name)
        return unless ignore_nick(m.user.nick).nil?
        return unless check_admin(m.user)
        begin
            factoid = Factoid.first :name => name.downcase
            if factoid.nil?
                raise "Factoid does not exist"
            else
                factoid.protect = false
                factoid.save
                m.reply "FactoidDB | Removed protection for factoid '#{factoid.name}'"
            end
        rescue Exception => x
            error x.message
            error x.backtrace.inspect
            m.reply "FactoidDB | Error | #{x.message}"
        end
    end
    
    match /fact(?:oid)? blame (.+?) \s*\/(.+)\//i, method: :getAddedBy
    def getAddedBy(m, name, regex)
        return unless ignore_nick(m.user.nick).nil?
        return unless !protect(m.user) and !shutup(m.user)
        
        begin
            factoid = Factoid.first :name => name.downcase
            if factoid.nil?
                raise "Factoid does not exist"
            else
                val = factoid.factoid_values.first(:value.like => "%#{regex}%")
                if val.addedBy.nil?
                    m.reply "FactoidDB | No blame info for '#{factoid.name}' => '#{val.value}'", true
                else
                    m.reply "FactoidDB | '#{val.addedBy}' is to blame for: '#{factoid.name}' => '#{val.value}'", true
                end
            end
        rescue Exception => x
            error x.message
            error x.backtrace.inspect
            m.reply "FactoidDB | Error | #{x.message}"
        end
    end
    
    match /fact(?:oid)? (?:remove|rm) (.+?) \s*\/(.+)\//i, method: :removeSpecificFactoid
    def removeSpecificFactoid(m, name, regex)
        return unless ignore_nick(m.user.nick).nil?
        return unless !protect(m.user) and !shutup(m.user)
        
        begin
            factoid = Factoid.first :name => name.downcase
            if factoid.nil?
                raise "Factoid does not exist"
            else
                if factoid.protect
                    if not check_admin(m.user)
                        m.reply "FactoidDB | Can't delete from '#{factoid.name}': factoid protected"
                        return
                    end
                end
                val = factoid.factoid_values.first(:value.like => "%#{regex}%")
                val.destroy
                m.reply "FactoidDB | Deleted factoid: '#{factoid.name}' => '#{val.value}'", true
            end
        rescue Exception => x
            error x.message
            error x.backtrace.inspect
            m.reply "FactoidDB | Error | #{x.message}"
        end
    end
        
    match /fact(?:oid)? (?:remove|rm) ([^\/]+)$/i, method: :removeFactoid
    def removeFactoid(m, name)
        return unless check_admin(m.user)
        return unless ignore_nick(m.user.nick).nil?
        return unless !protect(m.user) and !shutup(m.user)
        
        begin
            factoid = Factoid.first :name => name.downcase
            if factoid.nil?
                raise "Factoid does not exist"
            else
                if factoid.protect
                    if not check_admin(m.user)
                        m.reply "FactoidDB | Can't delete '#{factoid.name}': factoid protected"
                        return
                    end
                end
                factoid.factoid_values.all.destroy
                factoid.destroy
                m.reply "FactoidDB | Deleted factoid: '#{factoid.name}'", true
            end
        rescue Exception => x
            error x.message
            error x.backtrace.inspect
        	m.reply "FactoidDB | Error | #{x.message}"
        end
    end
    
end