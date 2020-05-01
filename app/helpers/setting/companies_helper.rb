module Setting::CompaniesHelper
	def companies_path
		if params[:action] == "new" || params[:action] == "create"
		  path = setting_companies_path
		elsif params[:action] == "edit" || params[:action] == "update"
		  path = setting_company_path(@company)
		end
		return path
	end
end