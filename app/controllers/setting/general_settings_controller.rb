class Setting::GeneralSettingsController < ApplicationController
  layout "setting"

  def index
    add_breadcrumb 'General Setting', :setting_general_settings_path
    @settings = GeneralSetting.order(:created_at)
  end

  def edit

  end

  def update
    params['general_setting'].keys.each do |id|
      @setting = GeneralSetting.find(id.to_i)
      @setting.update_attributes(params['general_setting'][id])
    end
    GeneralSetting.find(6).update_attributes!(background_image: params['general_setting']['6']['background_image'])
    redirect_to setting_general_settings_path
  end
end
