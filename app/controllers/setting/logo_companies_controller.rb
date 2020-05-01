class Setting::LogoCompaniesController < ApplicationController
	layout "main"

	def new
		@logo_company = LogoCompany.new
	end

	def create
		@logo_company = LogoCompany.new(params[:logo_company])
		if @logo_company.save
			respond_to do |f|
        f.js {
          render :js => "$('#span_change_logo').html('<img src=\"#{@logo_company.logo.small.url}\">')", :status => 200
        }
      end
		else
      respond_to do |f|
        f.js { flash[:error] = "Upload Image is unsuccessfully" }
      end
		end
	end

	def edit
		@logo_company = LogoCompany.find_by_id(params[:id])
	end

	def update
		@logo_company = LogoCompany.find(params[:id])
		if @logo_company.update_attributes(params[:logo_company])
			respond_to do |f|
        f.js {
          render :js => "$('#span_change_logo').html('<img src=\"#{@logo_company.logo.small.url}\">')", :status => 200
        }
      end
    else
      respond_to do |f|
        f.js { flash[:error] = "Upload Image is unsuccessfully" }
      end
		end
	end
end
