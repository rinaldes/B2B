class NotificationsController < ApplicationController
  layout 'main'
  before_filter :find_supplier, :except => [:new, :create]
  before_filter :find_object, :only => [:show_notif, :change_notif_state, :show, :edit, :generate_pdf_details_notification, :generate_xls_details_notification]
  load_and_authorize_resource

  def index
    add_breadcrumb 'Notification List', notifications_path
    conditions = []
    #@results = Notification.where(conditions.join(' AND ')).joins(:suppliers_notifications).order(default_order('notification')).accessible_by(current_ability).page(params[:page])
    if current_user.has_role?'superadmin'
      @results = Notification.where(conditions.join(' AND ')).order(default_order('notifications')).page(params[:page])
    else
      conditions << "valid_from<=NOW() AND valid_until>=NOW()"
      @results = current_user.notifications.where(conditions.join(' AND ')).order(default_order('notifications')).page(params[:page])
    end
  end

  def generate_pdf_details_notification
    render :pdf => "ASN-#{@notification.title}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/advance_shipment_notifications/asn.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def generate_xls_details_notification
    send_file @notification.export_to_xls, :disposition => 'inline', :type => 'application/xls', :filename => "ASN-#{@notification.title}.xls"
  end

  def update
    @notification = Notification.find(params[:id])
    if @notification.update_attributes(params[:notification])
      @notification.save_notif(params)
      respond_to do |f|
        f.html{
          if @notification.errors.any?
           flash[:error] = "An error has ocurred when sending notification, please try again later"
          else
          flash[:notice] = "notification has been send"
          end
         redirect_to notifications_path
        }
        f.js
      end
    else
      respond_to do |f|
        f.html{
          render :new
        }
      end
    end
  end

  def destroy
    @image_blast = Notification.find(params[:id])
    if @image_blast.destroy
      render :layout => false, :status => 201, :text => "The Notification has been removed"
    else
      render :layout => false, :status => 401, :text => "Sorry, the Notification can not be deleted "
    end
  end

  def short_notif
    @short_notifs = @supplier.suppliers_notifications.with_state(:unread).order("suppliers_notifications.created_at DESC")
  end

  def show_notif;end

  def change_notif_state
    @sn.read
    @sum_notif_unread_now=@supplier.suppliers_notifications.with_state(:unread).count
    render :nothing => true, :status => 200, :content_type => 'text/html'
  end

  def new
    add_breadcrumb 'Notification List', notifications_path
    add_breadcrumb 'New Notification', new_notification_path
  end

  def edit
  end

  def create
    @notification = Notification.new(params[:notification])
    if @notification.save
      @notification.save_notif(params)
      respond_to do |f|
        f.html{
          if @notification.errors.any?
           flash[:error] = "An error has ocurred when sending notification, please try again later"
          else
          flash[:notice] = "notification has been send"
          end
         redirect_to notifications_path
        }
        f.js
      end
    else
      respond_to do |f|
        f.html{
          render :new
        }
      end
    end
  end

  private
  def find_object
     @sn = Notification.find_by_id(params[:sn_id])
  end

  def find_supplier
    if current_user.supplier.nil?
      @supplier = Supplier.first
    else
      @supplier = current_user.supplier
    end
  end
end
