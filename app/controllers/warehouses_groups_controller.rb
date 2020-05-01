class WarehousesGroupsController < ApplicationController
  layout "main"
  before_filter :check_is_warehouse_only, :only => [:index,:show,:synch_warehouses_based_on_group]
  before_filter :find_group, :only => [:show,:synch_warehouses_based_on_group, :generate_pdf_details_warehouses_group, :generate_xls_details_warehouses_group]
  add_breadcrumb 'Warehouses Groups Master Data', :warehouses_groups_path
  authorize_resource :class => false

  def generate_xls_details_warehouses_group
    send_file @group.export_to_xls["path"], :disposition => 'inline', :type => 'application/xls', :filename => "WAREHOUSE GROUP-#{@group.name}.xls"
  end

  def generate_pdf_details_warehouses_group
    show
    render :pdf => "Payment-#{@group.name}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'warehouses_groups/warehouses_group.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def check_is_warehouse_only
    if current_user.type_of_user.parent.description == "Customer" || current_user.has_role?("superadmin")
      return true
    else
      respond_to do |f|
        f.js {render :layout => false, :status => 401}
      end
    end
  end

  def search_result
    conditions = ["group_type = 'Warehouse'"]
    conditions << "LOWER(to_char(created_at, 'Day, DD Month YYYY')) LIKE LOWER('%#{params[:update_at]}%')" if params[:update_at].present?
    conditions << "LOWER(code) LIKE LOWER('%#{params[:code]}%')" if params[:code].present?
    conditions << "LOWER(name) LIKE LOWER('%#{params[:name]}%')" if params[:name].present?

    @results = Group.where(conditions.join(' AND ')).order("created_at DESC").accessible_by(current_ability).page params[:page]

    respond_to do |format|
      format.js
    end
  end

  def index
    conditions = ["group_type = 'Warehouse'"]
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}::text) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @results = Group.where(conditions.join(' AND ')).search(params).order(default_order('groups')).accessible_by(current_ability).page params[:page]
    if (params["format"] == "xls")
      @results = Group.where(conditions.join(' AND ')).search(params).order(default_order('groups')).accessible_by(current_ability)
    end
    respond_to do |format|
      format.html
      format.js
      format.xls
    end
  end

  def show
    conditions = ["group_type = 'Warehouse'"]
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}::text) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    add_breadcrumb 'Warehouse', warehouses_group_path(params[:id])
    @results = @group.warehouses.order(default_order('groups')).joins(:group).accessible_by(current_ability).page(params[:page])
#    @results = @group.warehouses.order(default_order('warehouses')).accessible_by(current_ability).page(params[:page])
  end

  def generate_pdf_all_wg
      title = "WG_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = Group.where(["group_type = 'Warehouse'"].join(' AND ')).search(params).order(default_order('groups')).accessible_by(current_ability)
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'warehouses_groups/wg_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def synch_warehouses_based_on_group
    synch_warehouses = Warehouse.synch_warehouse_based_on_group_code(params[:group_code])
    status = eval_status_res(synch_warehouses)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      @results = @group.warehouses.search(params).order("id DESC").accessible_by(current_ability)#.page(params[:page])
      f.js {render :layout => false, :status => status}
    end
  end

  private

  def find_group
    if params[:id].present?
      @group = Group.where(:id => params[:id], :group_type => "Warehouse").first
    else
      @group = Group.where(:code => params[:group_code], :group_type => "Warehouse").first
    end
    not_found if @group.blank?
  end
end
