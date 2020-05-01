class Setting::TypeOfUsersController < ApplicationController
  layout "setting"
  before_filter :get_type_of_user, :only => [:edit, :update, :destroy]
  before_filter :current_company
  add_breadcrumb "Group User", :setting_type_of_users_path
  load_and_authorize_resource

  def index
    conditions = ["parent_id is not null"]
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}::text) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @results = TypeOfUser.where(conditions.join(' AND ')).order(default_order('type_of_users')).accessible_by(current_ability).page params[:page]
  end

  def edit
    add_breadcrumb "Change Group User based on Company", edit_setting_type_of_user_path(params[:id])
  end

  def update
    unless @type_of_user.group == "Supplier"
      @type_of_user.company_id = params[:type_of_user][:company_id]
      @type_of_user.description = params[:type_of_user][:description]
      if @type_of_user.save
        redirect_to setting_type_of_users_path, :notice => "Group User has been updated"
      else
        render "edit"
      end
    end
  end

  def get_this_company
    my_company = Company.first
    if my_company.present?
      @company_name = my_company.brand_tmp
      @company_id = my_company.id
    end
  end

  private

  def get_type_of_user
    @type_of_user = TypeOfUser.find(params[:id])
  end
end
