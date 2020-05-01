class WarehousesController < ApplicationController
	layout "main"
	before_filter :find_object, only: [:show]
  before_filter :get_level_limit, only: [:edit_level_limit, :update_level_limit]
	before_filter :get_email_notification, only: [:edit_email_notification]
  before_filter :get_areas, only: [:set_area, :update_area]
  add_breadcrumb 'Warehouse Groups Master Data', :warehouses_groups_path
	load_and_authorize_resource

	def index
	  @results = Warehouse.search(params).order("id DESC").accessible_by(current_ability).page params[:page]
	end

	def show
    add_breadcrumb 'Warehouse', warehouses_group_path(@warehouse.group_id)
    add_breadcrumb 'Warehouse Detail', warehouse_path(params[:id])
  end

  #desc: untuk pengeditan level limit per warehouse
  def edit_level_limit
  		add_breadcrumb 'Change Level Limit Warehouse', :edit_level_limit_warehouse_path
  end

  def update_level_limit
  	@update_limit_date = LevelLimit.save_level_limit(params)
  end

  #desc: synch warehouse berdasarkan warehouse yang ada, digunakan untuk update data jika terjadi perubahan
  def synch_warehouse_based_on_code
    wh_db = Warehouse.find(params[:id]).callback_api_warehouse_based_on_code
    status = eval_status_res(wh_db)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      f.js {render :layout => false, :status => status}
    end
  end

  #desc: untuk template email notification.
  def edit_email_notification
    add_breadcrumb 'Change Email Level Limit', :edit_email_notification_warehouse_path
     if @email_level_limit.nil?
      @email_level_limit = EmailLevelLimit.new(email_type: params[:type])
      @email_level_limit.warehouse_id = params[:warehouse_id]
      @email_level_limit.save
    end
  end

  def update_email_notification
    @email_level_limit = EmailLevelLimit.find_by_id(params[:email_level_limit][:id])
    if @email_level_limit.update_attributes(params[:email_level_limit])
      respond_to do |f|
        f.html{
          if @user.errors.any?
           flash[:error] = "An error has ocurred when saving email setting, please try again later"
          else
           flash[:notice] = "Email notification setting has been changed"
          end
          redirect_to root_path
        }
        f.js
      end
    end
  end

  def set_area
  end

  def update_area
    @update_area_on_warehouse = Warehouse.find(params[:warehouse_id])
    if @update_area_on_warehouse
      @update_area_on_warehouse.area_id = params[:area_id]
      if @update_area_on_warehouse.save
        render :text => @update_area_on_warehouse.area.area_name.to_s, :status => 200
      else
        render :text => "Failed to update area", :status => 400
      end
    else
      render :text => "Failed to update area", :status => 400
    end
  end

  #desc: synch warehouse ke API
  def synch_warehouses_now
    @results = Warehouse.synch_warehouses_now
    status = eval_status_res(@results)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      @back_to_index = "#{warehouses_groups_path}"
      f.js {render :layout => false, :status=>status}
    end
  end

  private
    def find_object
  	  @warehouse = Warehouse.find(params[:id])
  	end

  	def get_level_limit
     @level_limits = LevelLimit.where(:warehouse_id => params[:warehouse_id]).order("id ASC")
    end

    def get_email_notification
      @email_level_limit = EmailLevelLimit.find_by_warehouse_id_and_email_type(params[:warehouse_id], params[:type])
    end

    def get_areas
      @results = Area.order("area_name ASC").page params[:page]
    end
end
