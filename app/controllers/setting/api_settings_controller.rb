class Setting::ApiSettingsController < ApplicationController
	layout "setting"
  	add_breadcrumb 'Setting API Configuration', :new_setting_api_setting_path
  	load_and_authorize_resource

  	def new
  		@api_setting  = ApiSetting.first
  	end

  	def create
  		api_setting = ApiSetting.first.update_attributes(params[:api_setting])
  		if api_setting
  			redirect_to new_setting_api_setting_path, :notice => "API setting has changed successfully"
  		else
  			render 'new'
  		end
  	end
end
