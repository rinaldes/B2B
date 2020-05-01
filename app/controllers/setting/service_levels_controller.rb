class Setting::ServiceLevelsController < ApplicationController
  layout 'setting'
  before_filter :find_service_level, :only=> [:edit, :update, :destroy]
  def index
  	add_breadcrumb 'Setting Service Level', :setting_service_levels_path
    @results = ServiceLevel.search(params).order("sl_code DESC").accessible_by(current_ability).page params[:page]
  end

  def new
  	@servicelevel=ServiceLevel.new
  end

  def create
  	@servicelevel = ServiceLevel.new params[:service_level]
  	if @servicelevel.save
  	  redirect_to setting_service_levels_path , :notice=> "New service level has been created"
  	else
  	  render "new"
  	end
  end

  def update
  	if @servicelevel.update_attributes(params[:service_level])
      flash[:notice]="Service level was successfully updated"
      redirect_to setting_service_levels_path
    else
      render 'edit'
    end
  end

  def edit
  	add_breadcrumb 'Edit Service Level', :setting_service_level_path
  end

  def destroy
  	 if @servicelevel.destroy
      render :layout => false, :status => 201, :text => "Service level has been removed"
    else
      render :layout => false, :status => 401, :text => "Sorry, this service level can not be deleted now, try again tomorrow "
    end
  end
  private

  def find_service_level
  	@servicelevel=ServiceLevel.find(params[:id])
  end
end
