class Setting::RolesController < ApplicationController
  layout "setting"
  before_filter :check_role_group, :only => [:new, :edit, :create,:update]
  before_filter :find_object, :only => [:show, :edit,:update,:destroy,:add_features,:update_features, :update_features]
  load_and_authorize_resource @role, except: [:update_features]

  def index
    add_breadcrumb 'Setting Roles', :setting_roles_path
    conditions = []
    params[:search].each{|param|
      conditions << "#{param[0]}::text LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @results = Role.where(conditions.join(' AND ')).order(default_order("roles")).accessible_by(current_ability).page params[:page]
  end

  def show
    add_breadcrumb 'Role Detail', setting_role_path(@role.id)
  end

  def new
    @role = Role.new
    @all_features = Feature.find(:all)
    add_breadcrumb 'New Role', :new_setting_role_path
  end

  def create
    @role=Role.set_role(params, current_user)
    if !@role.errors.any?
      flash[:success]="Role has been created"
      redirect_to setting_roles_path
    else
      render 'new'
    end
  end

  def edit
    add_breadcrumb 'Edit Role', edit_setting_role_path(params[:id])
  end

  def update
    if @role.update_role(params)
      flash[:success]="Role has been updated"
      redirect_to setting_roles_path
    else
      render 'edit'
    end
  end

  def update_features
    if @role.save_features(params)
      flash[:notice]="Role successfully updated"
      redirect_to setting_roles_path
    else
      render 'edit'
    end
  end

  def destroy
    if @role.users.present?
      render :layout => false, :status => 401, :text => "Sorry, the role is still used"
    else
      if @role.destroy
        render :layout => false, :status => 201, :text => "Role has been removed"
      else
        render :layout => false, :status => 401, :text => "Sorry, role can not be removed now"
      end
    end
  end
  private
  #checked role group is Customer or supplier
  def check_role_group
    @roles = Role.role_group.accessible_by(current_ability)
  end

  def find_object
    @role=Role.find(params[:id])
  end
end
