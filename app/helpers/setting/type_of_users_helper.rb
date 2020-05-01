module Setting::TypeOfUsersHelper
  def find_group_for_type_of_user(name)
  	if name == 'Customer'
  		result = Company.first.brand_tmp
  	else
  		result = name
  	end
  	return result
  end
end
