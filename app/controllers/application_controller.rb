class ApplicationController < ActionController::Base
  before_filter :authenticate_user!
  protect_from_forgery
  before_filter :sum_notif
  before_filter :configure_permitted_parameters, if: :devise_controller?
  before_filter :check_breadcrumbs
  before_filter :show_warning_if_ldap_is_failure_connection
  before_filter :get_current_company, :only => [:print_list_po]
  before_filter :logo_company
  before_filter :current_company
  #before_filter :check_api
  before_filter :check_login,  if: :devise_controller?
  before_filter :check_expired, unless: :devise_controller?
  before_filter :set_controller_params

  require 'credential_ldap'
  require 'carrierwave/orm/activerecord'

  rescue_from CanCan::AccessDenied do |exception|
    not_authorized
  end
  rescue_from ActionController::RoutingError, :with => :not_found

  def set_controller_params
    @control = params[:controller].titleize
    @action = params[:action]
  end

  def default_order module_name=nil
    (params[:sort] || "#{module_name}#{'.' if module_name.present?}created_at DESC").to_s.gsub('-', ' ')
  end

  def not_found
    respond_to do |f|
      f.html{
        render "#{Rails.root.join('public','404.html')}",  :status => :not_found
      }
      f.js{
        render 'shared/not_found.js.erb'
      }
    end
  end

  def not_authorized
    respond_to do |f|
      f.html{
        render "#{Rails.root.join('public','401.html')}",  :status => :unauthorized
      }
      f.js{
        render 'shared/not_authorized.js.erb'
      }
    end
  end

  def something_wrong
    respond_to do |f|
      f.html{
        render "#{Rails.root.join('public','500.html')}",  :status => :internal_server_error
      }
      f.js{
        render 'shared/something_wrong.js.erb'
      }
    end
  end

  def forbidden
    respond_to do |f|
      f.html{
        render "#{Rails.root.join('public','422.html')}",  :status => :internal_server_error
      }
      f.js{
        render 'shared/forbidden.js.erb'
      }
    end
  end

  def no_content
    respond_to do |f|
      f.html{
        render "#{Rails.root.join('public','204.html')}",  :status => :no_content
      }
      f.js{
        render 'shared/no_content.js.erb'
      }
    end
  end

  def get_autocomplete_state
    if params[:id] == "returned_processes"
       arr = ['unread', 'read', 'received', 'disputed', 'rev','accepted']
    else
      case params[:id]
        when "purchase_orders"
          arr = ['new','open','on time','on time but less than 100', 'late','late but less than 100', 'expired']
        when "goods_receive_notes"
          arr = ['unread', 'read','dispute','rev','accepted']
        when "goods_receive_price_confirmations"
          arr = ['unread', 'read','dispute','rev','accepted']
        when "invoices"
          arr = ['new', 'printed','incomplete','completed','rejected']
        when "debit_notes"
          arr = ['pending', 'disputed', 'revisioned', 'accepted', 'rejected', 'expired']
        when "advance_shipment_notifications"
          arr = ['new','read', 'supplier edited', 'customer edited', 'accepted']
        when "payments"
          arr = ["pending", "rejected", "approved"]
        else
          arr = []
      end
    end
    @state = arr
    respond_to do |f|
      f.js {render :nothing=>true}
      f.json{
        render :json=>@state
      }
    end
  end

  def get_autocomplete_details
    case params[:type]
    when "suppliers"
      res  = Supplier.select("id, name").where("code ilike ? or name ilike ?", "%#{params[:id]}%","%#{params[:id]}%")
      resd = res.collect{|s| {:id => s.id, :label => s.name}}
    when "invoices"
      res  = PurchaseOrder.select("id, invoice_number").where("invoice_number ilike ?", "%#{params[:id]}%")
      resd = res.collect{|s| {:id => s.id, :label => s.invoice_number}}
    when "vouchers"
    end
    respond_to do |f|
      f.js {render :nothing=>true}
      f.json{
        render :json=>resd
      }
    end
  end

  def new_print
    @order_type = params[:id]
    respond_to do |f|
       f.js{ render 'shared/new_print.js.erb'}
    end
  end

  def print_list_po
    order_type=''
    if params[:id] == "returned_processes"
       @results = ReturnedProcess.search(params).order("created_at DESC").where(:is_completed=>true, :is_history => false).accessible_by(current_ability)
    else
      case params[:id]
         when "purchase_orders"
          order_type = "#{PO}"
        when "goods_receive_notes"
          order_type = "#{GRN}"
        when "goods_receive_price_confirmations"
          order_type = "#{GRPC}"
        when "invoices"
          order_type = "#{INV}"
        when "advance_shipment_notifications"
          order_type = "#{ASN}"
      end
      params[:controller]="order_to_payments/#{params[:id]}"
      if params[:search][:field] == "Proforma Invoice Number"
        params[:search][:field] = "Invoice Number"
      end
      @results = PurchaseOrder.search(params.except(:selisih_tax, :selisih_dpp)).order("created_at DESC").where(:order_type=> "#{order_type}", :is_completed=>true, :is_history => false).accessible_by(current_ability)
      if order_type == INV
        @results.update_all(:tax_gap => params[:selisih_tax].gsub(/[^\d\,]/, '').to_i,
                            :dpp_gap => params[:selisih_dpp].gsub(/[^\d\,]/, '').to_i)
      end
    end
    @params = params.except("controller", "utf8", "action", "button")
    render :pdf => "list purchase orders",
          :disposition => 'inline',
          :layout=> 'layouts/invoice.pdf.erb',
          :template => 'shared/list_po.pdf.erb',
          :page_size => 'A4',
          :lowquality => false

  end

  def eval_status_res(res)
    case res
      when true
        status = 200
      when 1
        status = 500
      when 2
        status = 503
      when -1
        status = 204
      when -2
        status = 206
      when -3
        status = 401
      when -4
        status = 404
      when -5
        status = 508
      when -6
        status = 509
      else
        status = 500
    end
    return status
  end

  def send_email_which_service_api_is_not_connected(status)
    message = ""
    req = false
    case status
    when 503
      message = "Service API is unavailable right now."
      req = true
    when 404
      message = "Service API not found on server"
      req = true
    when 401
      message = "System can't access the server"
      req = true
    when 408
      message = "Request time out"
      req = true
    when 422
      message = "Data can't be processed by server"
      req = true
    end
    message += " \nURL From #{BASE_URI} AND API From #{ApiSetting.finds('api')}"
    if req
      UserMailer.mailer_notification_api_is_not_response(message,RECEIVE_EMAIL_API_IS_NOT_CONNECTED).deliver
    end
  end

  protected

  def check_from_ldap
    status_ldap = session[:status_ldap]
    user = User.check_is_ldap_user(params, config_ldap_from_db, status_ldap)
    if user
      sign_in user
    end
  end

  def sum_notif
    if user_signed_in?
      if current_user.supplier.nil?
        supplier = Supplier.first
      else
        supplier = current_user.supplier
      end
      @sum_notif = supplier.try(:suppliers_notifications).with_state(:unread).count rescue 0
    end
  end

  def current_company
    @my_company = Company.first
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:login) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
  end

  def after_sign_in_path_for(user)
    unless session["warden.user.user.key"].blank?
      id = session["warden.user.user.key"].flatten.first
    else
      id = UserLog.last.user_id
    end
    result = User.find(id)
    if result.signed == 1
        if session[:user_log].blank?
          destroy_user_session_path
        else
          root_path
        end
    else
      if user.update_attributes(:has_signed_in => true)
        result.update_attributes(:signed =>1, :expired_activity_at => (Time.now + 15.minutes))
        save_history_login_user = UserLog.new(:login_date => Time.now)
        save_history_login_user.user_id = current_user.id
        save_history_login_user.save
        session[:user_log] = save_history_login_user.id
        root_path
      end
    end
  end

  def after_sign_out_path_for(user)
    unless session["warden.user.user.key"].blank?
      id = session["warden.user.user.key"].flatten.first
    else
      id = UserLog.last.user_id
    end
    sign_out = User.find(id)
    unless session[:user_log].present?
       sign_out.update_attributes(has_signed_in: true, :signed =>1)
       new_user_session_path(:login => 0)
    else
      if sign_out.signed == 1 || sign_out.signed == 0
        if params[:real].present?
          sign_out.update_attributes(has_signed_in: false, :signed =>nil)
          UserLog.find(session[:user_log]).update_attributes(:logout_date => Time.now)
          session.delete(:user_log)
          new_user_session_path
        else
          new_user_session_path(:login => 0)
        end
      end
    end
  end

  def check_breadcrumbs
    if request.filtered_parameters["controller"].split('/').first == "setting"
      add_breadcrumb "Settings", :setting_roles_path
    else
      add_breadcrumb "Dashboard", :root_path
    end
  end

  def get_current_company
    @company = current_user.type_of_user.company
  end

  def current_warehouse
    if current_user.warehouse.present?
      current_user.warehouse
    else
      nil
    end
  end

  def current_supplier
    if current_user.supplier.present?
      current_user.supplier
    else
      nil
    end
  end

  def is_default_user?
    current_user.has_role? :default_user
  end

  def is_group_admin?
    return true if current_user.roles.first.group_flag
  end

  def config_ldap_from_db
    LdapSetting.first
  end

  def show_warning_if_ldap_is_failure_connection
    ldap = config_ldap_from_db
    unless user_signed_in?
      if params[:controller].downcase == "devise/sessions"
        unless CredentialLdap.is_valid_credential?(ldap.ldap_host, ldap.ldap_port)
          flash[:show_warning_ldap] = "Warning : LDAP Setting Not valid, please contact administrator"
          session[:status_ldap] = false
        else
          session[:status_ldap] = true
        end
        check_from_ldap
      end
    end
  end

  def change_words(obj)
    return obj.verb.conjugate :tense => :past, :aspect => :perfective
  end

  def logo_company
    @logo = LogoCompany.last
  end

  def check_login
    if params[:action] == 'create'
      result = User.find_by_username(params[:user][:login])
      unless result.blank?
        valid = result.valid_password?(params[:user][:password])
        if valid
          #result = User.find_by_username(params[:user][:login])
          unless result.blank?
            if result.signed == 1
              db_time = (result.expired_activity_at).to_s
              time = (Time.now - 7.hours).to_s
              if time > db_time
                result.update_attributes(:has_signed_in => false, :signed =>nil)
              end
            end
          end
        end
      end
    end
  end

  def check_expired
    unless current_user.blank?
      result = User.find(current_user.id)
      unless result.blank?
        if result.signed == 0 #Status for Force Logout
          redirect_to destroy_user_session_path(:real => true)
        else
          result.update_attributes(:expired_activity_at => (Time.now + 15.minutes))
        end
      end
    end
  end
end
