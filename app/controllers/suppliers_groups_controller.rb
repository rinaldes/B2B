class SuppliersGroupsController < ApplicationController
  layout "main"
  before_filter :find_group, :only => [:show, :edit_level, :update_level,:synch_suppliers_based_on_group, :generate_xls_details_suppliers_group, :generate_pdf_details_suppliers_group]
  add_breadcrumb 'Supplier Groups Master Data', :suppliers_groups_path
#  authorize_resource except: :generate_pdf_details_suppliers_group
  def index
  	@results = Group.search(params).order(begin params[:sort] + " " + params[:direction] rescue 'code' end).accessible_by(current_ability).where(:group_type => "Supplier").page params[:page]
    if (params["format"] == "xls")
      @results = Group.search(params).order(begin params[:sort] + " " + params[:direction] rescue 'code' end).accessible_by(current_ability).where(:group_type => "Supplier")
    end
    conditions = ["group_type = 'Supplier'"]
    params[:search].each{|param|
      conditions << "#{param[0]}::text LIKE '%#{param[1]}%'"
    } if params[:search].present?
  	@results = Group.where(conditions.join(' AND ')).order(default_order('groups')).accessible_by(current_ability).page params[:page]
    respond_to do |format|
      format.html
      format.js
      format.xls
    end
  end

  def generate_xls_details_suppliers_group
    send_file @group.export_to_xls["path"], :disposition => 'inline', :type => 'application/xls', :filename => "SUPPLIER GROUP-#{@group.code}.xls"
  end

  def generate_pdf_details_suppliers_group
    show
    render :pdf => "Payment-#{@group.name}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'suppliers_groups/suppliers_group.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def generate_pdf_all_sg
      title = "SG_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = Group.search(params).order(begin params[:sort] + " " + params[:direction] rescue 'code' end).accessible_by(current_ability).where(:group_type => "Supplier")
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'suppliers_groups/sg_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def show
    add_breadcrumb 'Supplier', suppliers_group_path(params[:id])
    @results = @group.suppliers.search(params).order(begin params[:sort] + " " + params[:direction] rescue 'code' end).joins(:group).accessible_by(current_ability).page(params[:page])
  end

  def edit_level
  end

  def synch_suppliers_based_on_group
    synch_suppliers = Supplier.synch_supplier_based_on_group_code(params[:group_code])
    status = eval_status_res(synch_suppliers)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      @back_to_index = "#{suppliers_groups_path}"
      f.js {render :layout => false, :status => status}
    end
  end

  def update_level
    @group.level = params[:group][:level].to_i
    if @group.save && @group.set_feature("supplier", current_user, params)
      return @group
    else
      render "edit_level"
    end
  end

  private
  def find_group
  	if params[:id].present?
      @group = Group.where(:id => params[:id], :group_type => "Supplier").first
    else
      @group = Group.where(:code => params[:group_code], :group_type => "Supplier").first
    end
  	not_found if @group.blank?
  end
end
