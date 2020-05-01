class Setting::LdapSettingsController < ApplicationController
  layout "setting"
  add_breadcrumb 'Setting LDAP Configuration', :new_setting_ldap_setting_path
  load_and_authorize_resource
  def new
    @ldap_setting = LdapSetting.first
  end

  def create
    @ldap_setting = LdapSetting.first
    ldap_change = @ldap_setting.save_change_setting_ldap(current_user, params[:ldap_setting])
    if ldap_change
      redirect_to new_setting_ldap_setting_path, :notice => "LDAP setting has changed successfully"
    else
      render 'new'
    end
  end
end
