class Setting::CompaniesController < ApplicationController
  layout 'setting'
  add_breadcrumb 'Company Profile', :setting_companies_path

  def create
  	@company = Company.new(params[:company])
  	if @company.save
  	  redirect_to setting_companies_path, :notice=>"Company profile created"
    else
      render 'new'
    end
  end

  def new
    add_breadcrumb 'Add Company Profile', :new_setting_company_path
  	@company=Company.new
    @company.addresses.build
  end

  def edit
    add_breadcrumb 'Edit Company Profile', :edit_setting_company_path
  	@company = Company.find(params[:id])
    if  @company.addresses.blank?
      @company.addresses.build
    end
  end

  def update
  	@company = Company.find(params[:id])
    if @company.update_attributes(params[:company])
      redirect_to setting_companies_path, :notice=> "Company profile edited"
    else
      render 'edit'
    end
  end

  def index
    @company = Company.first
  end
end
