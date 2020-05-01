class Setting::UserLevelDisputesController < ApplicationController
  layout "setting"
  #before_filter :get_type_of_user, :only => [:edit, :update, :destroy]
  #before_filter :current_company
  add_breadcrumb "Group User", :setting_user_level_disputes_path
  load_and_authorize_resource

  def index
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}::text) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @results = UserLevelDispute.select("user_level_disputes.*, users.username AS username").where(conditions.join(' AND ')).joins(:dispute_setting,:user).order(default_order('user_level_disputes')).page params[:page]
  end

  def new
    @user_level_dispute = UserLevelDispute.new
  end

  def create
    @user_level_dispute = UserLevelDispute.new(params[:user_level_dispute])
    if @user_level_dispute.save
      redirect_to setting_user_level_disputes_path
    else
      render 'new'
    end
  end

  def edit
    add_breadcrumb "Edit User Level Dispute", edit_setting_user_level_dispute_path(params[:id])
  end

  def update
    @user_level_dispute = UserLevelDispute.find(params[:id])
    if @user_level_dispute.update_attributes(params[:user_level_dispute])
      redirect_to setting_user_level_disputes_path
    else
      render 'edit'
    end
  end

  def destroy
    @image_blast = UserLevelDispute.find(params[:id])
  	if @image_blast.destroy
      render :layout => false, :status => 201, :text => "User Level Dispute has been removed"
    else
      render :layout => false, :status => 401, :text => "Sorry, User Level Dispute can not be deleted "
    end
  end
end
