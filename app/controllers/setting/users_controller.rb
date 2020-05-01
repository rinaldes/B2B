class Setting::UsersController < ApplicationController
  layout "setting"
  before_filter :data_roles, :only => [:new, :edit, :create, :update]
  before_filter :get_user, :only=> [:show, :edit, :update, :force_logout]
  before_filter :get_group_user, :only => [:new, :create, :edit, :update]
  load_and_authorize_resource

  def index
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @results = User.where(conditions.join(' AND ')).order(default_order('users')).accessible_by(current_ability).page(params[:page])
    respond_to do |format|
      format.html
      format.js
      format.xls
    end
    add_breadcrumb 'Setting Users', :setting_users_path
  end

  def new
    add_breadcrumb "Register User", new_setting_user_path
    @register = User.new
  end

  def create
    @register = User.new params[:user]
    if @register.save_register_user(params)
      save_roles(@register)
      redirect_to setting_users_path, :notice => "Thank You, User has been created"
    else
      render "new"
    end
  end

  def show
    add_breadcrumb 'Setting Users', :setting_users_path
    add_breadcrumb "Detail Users '#{@user.first_name.try(:camelize)} #{@user.last_name.try(:camelize)}'", setting_user_url(@user)
  end

  def features
    add_breadcrumb 'Setting Users', :setting_users_path
    add_breadcrumb 'Detail User', setting_user_path(params[:id])
    add_breadcrumb "Change Feature '#{@user.first_name.try(:camelize)} #{@user.last_name.try(:camelize)}'", features_setting_user_path(@user)
    @user = User.find(params[:id])
  end

  def edit
    add_breadcrumb "Register User", edit_setting_user_path
  end

  def update_features
    @user = User.find(params[:id])
    if @user.save_features(params, current_user)
      flash[:notice]="Feature successfully updated"
      redirect_to setting_user_path(@user)
    else
      render 'features'
    end
  end

  def update
    if @user.update_user(params)
      update_roles(@user)
      redirect_to setting_users_path, :notice => "Thank You, User has been update"
    else
      render "edit"
    end
  end

  #edit password an account
  def change_password
    @user=User.find(current_user)
  end

  def select_supplier_or_warehouse
    selected_user = params[:id]
    if params[:key] == "supplier"
      if current_user.has_role?("superadmin")
        @results = Group.where(:group_type => "Supplier").search(params).page(params[:page])
      else#if current_user.is_supplier_admin_group
        @results = Supplier.search(params).order("id DESC").accessible_by(current_ability).page(params[:page])
      end
      @flag = "supplier"
    elsif params[:key] == "customer"
      if current_user.has_role?("superadmin")
        @results = Group.where(:group_type => "Warehouse").search(params).page(params[:page])
      else#if current_user.is_customer_admin_group
        @results = Warehouse.search(params).order("id DESC").accessible_by(current_ability).page(params[:page])
      end
      @flag = "customer"
    end
  end
  #action when edit password
  def update_password
    @user = User.find(current_user.id)
    unless !@user.check_password? params[:user]
      if @user.update_with_password(params[:user])
        sign_in @user, :bypass => true
      else
        @user.errors[:current_password].shift
        @user.errors.add(:current_password, "The given password is invalid")
        render "change_password", :user => @user
      end
    else
      render "change_password", :user => @user
    end
  end

  def change_activation
    change_status = User.find(params[:id]).change_activation(current_user)
    if change_status[0]
      redirect_to setting_user_path(params[:id]), :notice => change_status[1]
    else
      redirect_to setting_user_path(params[:id]), :alert => change_status[1]
    end
  end

  def check_is_supplier

    unless params[:group_id].blank? || params[:group_id] == "undefined"
      type_of_user = TypeOfUser.accessible_by(current_ability).find(params[:group_id])
      render :text => type_of_user.parent.description, :layout => false
    else
      type_of_user = nil
      render :text => type_of_user, :layout => false
    end

  end

  def change_email_notif
    @user = User.find(params[:id])
    not_found if @user.nil?
    respond_to do |f|
      f.js
    end
  end

  def update_change_email_notif
    @user = User.find(params[:id])
    not_found if @user.nil?
    if @user.update_attributes(params[:user])
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

  def mutation
    user = User.find(params[:id])
    if user.type_of_user.try(:parent).try(:description) == "Supplier"
      @results = Supplier.search(params).order("id DESC").accessible_by(current_ability).page(params[:page])
      @flag = "mutation_to_another_supplier"
    else
      @results = Warehouse.search(params).order("id DESC").accessible_by(current_ability).page(params[:page])
      @flag = "mutation_to_another_warehouse"
    end
  end

  def update_mutation
    user = User.find(params[:id])
    unless params[:supp_wh_id].blank? || params[:supp_wh_id] == "undefined"
      if params[:mutation_type] == "supplier"
        user.supplier_id = params[:supp_wh_id]
      else
        user.warehouse_id = params[:supp_wh_id]
      end
      if user.save
        respond_to do |f|
          f.html{
            if user.errors.any?
             flash[:error] = "An error has ocurred when saving email setting, please try again later"
            else
             flash[:notice] = "Email notification setting has been changed"
            end
            redirect_to setting_users_path
          }
          f.js
        end
      end
    else

    end
  end

  def force_logout
    @user.update_attributes(:signed => 0)
    flash[:notice] = "Account has been Logout"
      redirect_to setting_users_path
  end

private
  #find id user
  def get_user
    @user = User.find(params[:id])
      if params[:action] == "force_logout"
        @user.update_attributes(:signed => 0)
        flash[:notice] = "Account has been Logout"
          redirect_to setting_users_path
      end
  end

  #find id supplier
  def get_supplier
    @supplier = Supplier.find_by_id(params[:supplier_id])
  end

  #after save user, create role the user
  def save_roles user
    user.add_role(params[:role_name])
  end

  def update_roles user
    r_name = user.roles.first.name
    user.remove_role(r_name)
    user.add_role(params[:role_name])
  end

  #checked role based on current user is admin, supplier or customer
  def data_roles
    if current_user.has_role? :superadmin
      @roles = Role.only_super_admin.accessible_by(current_ability)
    else
      unless current_user.warehouse.blank?
        roles = "customer"
      else
        roles = "supplier"
      end
      @roles = Role.only_admin_group(roles)
    end
  end

  def get_group_user
    @group = TypeOfUser.accessible_by(current_ability).where("parent_id is not null")
  end
end
