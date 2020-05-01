class SuppliersController < ApplicationController
  layout "main"
  before_filter :find_object, :only => [:show,:edit_level,:update_level, :edit_service_level, :update_service_level]
  before_filter :codes, :only => [:edit_service_level, :update_service_level]
  before_filter :get_level_limit, :only => [:edit_level_limit, :update_level_limit]
  add_breadcrumb 'Supplier Groups Master Data', :suppliers_groups_path

  load_and_authorize_resource
  def index
 	  @results = Supplier.search(params).order("id DESC").accessible_by(current_ability)#.page params[:page]
  end

  def edit_level
  end

  #desc: update level untuk smua supplier
  def update_level
    @supplier.level = params[:supplier][:level].to_i
    if @supplier.save
      return @supplier
    else
      render "edit_level"
    end
  end

  def show
    add_breadcrumb 'Supplier', suppliers_group_path(@supplier.group.id)
    add_breadcrumb 'Supplier Detail', supplier_path(params[:id])
  end

  #desc: service level
  def edit_service_level
     @results = ServiceLevel.search(params).order("id DESC").accessible_by(current_ability).page(params[:page]).per(5)
  end

  #desc: edit barcode setting per supplier
  def edit_barcode_setting
    @barcode = {'-Pilih-' => 0, 'PO Number' => 1, 'GRN Number' => 2, 'Invoice Number' => 3 }
    @barcode_settings = BarcodeSettingsSupplier.where(:supplier_id => params[:id]).order("number ASC")
  end

  def update_barcode_setting
    @supplier = Supplier.find_by_id(params[:id])
    @supplier.update_barcode_settings(params["supplier_priority"])

  unless @supplier.errors.any?
    unless @supplier.errors.messages[:priority].present?
     BarcodeSettingsSupplier.update_barcode_settings(params)
    end
  end
  respond_to do |format|
     format.js
  end
    #@barcode_settings = BarcodeSettingsSupplier.update_barcode_settings(params)
  end

  def update_service_level
    if params[:supplier].nil?
      @supplier.errors.add(:service_level_code, "Please choose a service level")
    else
      sl=ServiceLevel.find_by_sl_code(params[:supplier][:service_level_code])
      if !sl.nil?
        @supplier.service_level_id = sl.id
        unless @supplier.save
           @supplier.errors.add(:service_level_code, "An error has ocurred on saving service level, please try again")
        end
      else
        @supplier.errors.add(:service_level_code, "The code is not available")
      end
    end
  end

  #desc : synch supplier to API
  def synch_suppliers_now
    @results = Supplier.synch_suppliers_now
    status = eval_status_res(@results)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      @results = Group.search(params).order("id DESC").where(:group_type => "Supplier").accessible_by(current_ability).page params[:page]
      f.js {render :layout => false, :status => status}
    end
  end

  #desc: synch supplier berdasarkan data suplier yg sudah ada, system UPDATE
  def synch_supplier_based_on_accountcode
    @results = Supplier.find(params[:id]).callback_update_supplier_from_api
    status = eval_status_res(@results)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      f.js {render :layout => false, :status => status}
    end
  end

  private
  def find_object
    @supplier = Supplier.find(params[:id])
    not_found if @supplier.nil?
  end

  def codes
    @codes = ServiceLevel.pluck(:sl_code)
    @codes = @codes.to_json
  end

  def get_level_limit
     @level_limits = LevelLimit.where(:supplier_id => params[:supplier_id]).order("id ASC")
  end
end
