class Setting::BrandCompaniesController < ApplicationController
	layout "main"

	def edit
		@brand_company = Company.find(params[:id])
	end

	def update
		@brand_company = Company.find(params[:id])
		respond_to do |format|
			if @brand_company.update_attributes(params[:brand_company])
				format.js{render :js => "$('#span_change_brand').html('<small>#{@brand_company.brand_tmp}</small>')", :status => 200}
			else
				 f.js { flash[:error] = "Company Name unsuccessfully updated" }
			end
		end
	end
end
