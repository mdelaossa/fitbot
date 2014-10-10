module UtilityFunctions
    # Ignore list
    def ignore_nick(user)
        check = IgnoreDB.first(:nick => user.downcase)
    	check.nil? ? (return nil) : (return true)
    end
    
    # Passive on/off
    def disable_passive(channel)
    	check = PassiveDB.first(:channel => channel.downcase)
    	check.nil? ? (return nil) : (return true)
    end
    
    # Passive on/off
    def disable_passive_files(channel)
    	check = PassiveFDB.first(:channel => channel.downcase)
    	check.nil? ? (return nil) : (return true)
    end
    
    # Autoconvert on/off
    def disable_autoconvert(channel)
        check = AutoconvertDB.first(:channel => channel.downcase)
        check.nil? ? (return nil) : (return true)
    end
    
    # Bot admins
    def check_admin(user)
    	user.refresh
        return false if user.authname.nil?
    	@admins = AdminDB.first(:nick => user.authname.downcase)
    end
    
    def check_admin_kick(m)
        isAdmin = check_admin(m.user)
        m.channel.kick(m.user, "http://i.imgur.com/w7lGFWM.jpg") unless isAdmin
        isAdmin
    end
end