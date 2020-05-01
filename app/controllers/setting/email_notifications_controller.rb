class Setting::EmailNotificationsController < ApplicationController
	layout "setting"
	add_breadcrumb 'Email Notification', :setting_email_notifications_path
  before_filter :get_email_notification, only: [:load_email_form]
	def index;end

	def load_email_form
    if @email_notification.nil?
      @email_notification = EmailNotification.new(email_type: params[:email_type])
      @email_notification.save
    end
	end

	def update
		@email_notification = EmailNotification.find_by_id(params[:id])
    @id_form = params[:id_form]
		if @email_notification.update_attributes(params[:email_notification])
      respond_to do |f|
        f.html{
          if @email_notification.errors.any?
           flash[:error] = "An error has ocurred when saving email setting, please try again later"
          else
           flash[:notice] = "Email notification setting has been changed"
          end
          redirect_to setting_email_notifications_path
        }
        f.js
      end
    end
	end

  private

  def get_email_notification
    @email_notification = EmailNotification.find_by_email_type(params[:email_type])
  end

end
