class Setting::DisputeSettingsController < ApplicationController
  layout "setting"

  def index
    add_breadcrumb 'Dispute Setting', :setting_dispute_settings_path
    @results = DisputeSetting.search(params).order("transaction_type DESC").accessible_by(current_ability).page params[:page]
    #@results = DisputeSetting.order("id ASC").accessible_by(current_ability).page params[:page]
  end

  def new
    #add_breadcrumb "New Dispute Setting", new_setting_dispute_settings_path
    @register = DisputeSetting.new
  end

  def create
    @register = DisputeSetting.new params[:dispute_setting]
    if @register.save(params)
      redirect_to setting_dispute_settings_path, :notice => "Thank You, Dispute Setting has been created"
    else
      render "new"
    end
  end

  def edit
    #add_breadcrumb 'Edit Dispute Setting', edit_setting_dispute_setting_path
    @dispute = DisputeSetting.find(params[:id])
  end

  def update
    @dispute = DisputeSetting.find(params[:id])
    if @dispute.update_attributes(params[:dispute_setting])
      redirect_to setting_dispute_settings_path, :notice => "Thank You, Dispute Setting has been update"
    else
      render "edit"
    end
  end

  def destroy
    @dispute = DisputeSetting.find(params[:id])
    if @dispute.destroy
      render :layout => false, :status => 201, :text => "The Dispute has been removed"
    else
      render :layout => false, :status => 401, :text => "Sorry, the dispute setting can not be deleted "
    end
  end
end
