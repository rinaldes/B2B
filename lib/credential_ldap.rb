#author: leonardo
#desc: added creadential user with LDAP
module CredentialLdap
  def self.setup_ldap(params, ldap_config)
    if is_valid_credential? "#{ldap_config.ldap_host}", ldap_config.ldap_port
      ldap = Net::LDAP.new :host => "#{ldap_config.ldap_host}",
         :port => ldap_config.ldap_port,
         :base => "#{ldap_config.ldap_base}",
         :auth => {
           :method => :simple,
           :username => "cn=#{params[:user][:login]}, #{ldap_config.ldap_base}",
           :password => "#{params[:user][:password]}"
          }
      return ldap
    else
      return false
    end
  end

  #author: leonardo
  #desc: check internet connection
  def self.is_valid_credential?(addr, port)
    if FileTest.exist?("#{Rails.root.join('lib', 'check_ldap.sh')}")
      `cp lib/check_ldap.sh lib/check.sh`
      `sed -i 's/addr/#{addr}/g' lib/check.sh && sed -i 's/port/#{port}/g' lib/check.sh`
      status = `./lib/check.sh`
      message=''
      `rm lib/check.sh`
      if status.to_i == 0
        message =`nc -vz -w10 #{addr} #{port} 2>&1  | grep ldap`
      end

      if  status.to_i == 0 && !message.blank?
        output=message.split(" ")
        if output.include?("open") || output.include?("succeeded!")
          return true
        else
          return false
        end
      else
        return false
      end
    else
      return false
    end
  end

end