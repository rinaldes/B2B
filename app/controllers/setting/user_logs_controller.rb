class Setting::UserLogsController < ApplicationController
  layout "setting"
  load_and_authorize_resource

  add_breadcrumb "User Logs", :setting_user_logs_path
  def index
    if params[:history_log_selected].blank? || params[:history_log_selected].to_s == "0"
      @results = UserLog.history_login_activity.filter(params,current_user).accessible_by(current_ability).order("created_at DESC").page params[:page]
    else
      @results = UserLog.history_transaction_activity.where("user_logs.login_date is NULL OR user_logs.logout_date is NULL").filter(params, current_user).order("user_logs.created_at DESC").page params[:page]
    end
  end

  def login_history
    @results = UserLog.history_login_activity.filter(params,current_user).accessible_by(current_ability).order("created_at DESC").page params[:page]
      respond_to do |f|
        f.js { render :partial => "setting/user_logs/results_history_login_activity",:layout => false, :locals => {:results => @results} }
      end
  end

  def transaction_history
    @results = UserLog.history_transaction_activity.where("user_logs.login_date is NULL OR user_logs.logout_date is NULL").filter(params, current_user).order("user_logs.created_at DESC").page params[:page]
      respond_to do |f|
        f.js { render :partial => "setting/user_logs/results_history_transaction_activity",:layout => false, :locals => {:results => @results} }
      end
  end
end
