class Setting::FeaturesController < ApplicationController
  include List_features
  layout 'setting'
  before_filter :find_feature, :only => [:edit, :update, :destroy]
  before_filter :avalaible_features, :only => [:new, :edit, :create, :update]
  load_and_authorize_resource
  def index
  	add_breadcrumb 'Setting Features', :setting_features_path
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}::text) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @results =Feature.where(conditions.join(' AND ')).order(default_order('features')).accessible_by(current_ability).page params[:page]
  end

  def new
    add_breadcrumb 'New Feature', :new_setting_feature_path
  	@feature = Feature.new
  end

  def create
  	@feature = Feature.new params[:feature]
  	if @feature.save
  	  flash[:success]="Successfully created feature"
  	  redirect_to setting_features_path
  	else
      render "new"
  	end
  end

  def edit
  	add_breadcrumb 'Edit Feature', :edit_setting_feature_path
  end

  def update
    if @feature.update_attributes(params[:feature])
      flash[:notice]="Feature successfully updated"
      redirect_to setting_features_path
    else
      render 'edit'
    end
  end

  def destroy
    if @feature.destroy
      render :layout => false, :status => 201, :text => "The feature has been removed"
    else
      render :layout => false, :status => 401, :text => "Sorry, the feature can not be deleted "
    end
  end

  private
    #checked feature is present or not
    def find_feature
      @feature = Feature.find(params[:id])
      if !@feature
        flash[:error] = "Feature not existed"
        redirect_to setting_features_url
      end
    end

    #check feature from lib
    def avalaible_features
  	  @names = list_all_controller
  	  return @names
    end
end

