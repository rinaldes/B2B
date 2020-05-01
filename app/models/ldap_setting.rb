class LdapSetting < ActiveRecord::Base
   belongs_to :user
   belongs_to :company
   attr_accessible :ldap_host, :ldap_port, :ldap_base, :ldap_method, :description
   attr_protected :user_id

   before_save { |ldap| ldap.ldap_method = "simple" }

   validates :ldap_host, :presence => {:message => "Host can't be Empty", :allow_blank => false}
   validates :ldap_port, :presence => {:message => "Port can't be Empty", :allow_blank => false}
   validates :ldap_base, :presence => {:message => "Base can't be Empty", :allow_blank => false}
   validates :ldap_method, :presence => {:message => "Method can't be Empty", :allow_blank => false}, inclusion: { in: %w(simple), :message => "Sorry, %{value} is not in method. Please fill 'simple' of method"}

  def save_change_setting_ldap(user, params)
    self.ldap_host = params[:ldap_host]
    self.ldap_port = params[:ldap_port]
    self.ldap_base = params[:ldap_base]
    self.description = params[:desc]
    self.user_id = user.id
    self.save
  end
end
