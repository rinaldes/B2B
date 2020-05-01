after :users do
  ldap = LdapSetting.first
  users = User.order("id DESC")
  user = ""
  users.collect{|u|
    user = u if u.has_role? :superadmin
  }

  unless ldap
    puts "Create Default LDAP Setting"
    puts "======================================"

    ldap_setting = LdapSetting.new(
    :ldap_host => '192.168.0.20',
    :ldap_port => 389,
    :ldap_base => 'cn=b2b,dc=ldap,dc=lokal',
    :ldap_method => 'simple')
    ldap_setting.user_id = user.id

    if ldap_setting.valid? && ldap_setting.save
      puts "Create Default LDAP Setting Successfully"
      puts "======================================"
    end
  else
    puts "do nothing"
  end
end