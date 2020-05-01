module Setting::RolesHelper
  def display_role_features(controller)
    if controller.split(" ").count > 1
       regulator = controller.split(" ").join("")
    else
      regulator = controller
    end
    regulator = controller.split(" ").join("")
    str = "<table border='0' id='check-box_#{regulator}'>"
    str += "<tr><td>"
    str += check_box_tag "#{regulator}_all", 'all', false, class: 'check-all',:onclick=>"check_all('#{controller}')"
    str += "<span class='lbl'><h5 style='margin: -19px 0 0 20px; position: absolute; width: 260px'>#{controller}</h5></span>"
    str += "</td></tr>"
    for feature in Feature.order("name asc").where(:regulator => regulator)
      str += "<tr><td>"
      str += check_box_tag 'role[feature_ids][]', feature.id, @role.features.include?(feature), :class => ''
      str += "<span class='lbl'> #{feature.name}</span>"
      str += "</td></tr>"
    end
    str += "</table>"
    return str
  end

  def hide_action_button_for_default_role(role_name)
    return true unless role_name.downcase == "supplier" || role_name.downcase == "customer" || role_name.downcase == "default_user" || role_name.downcase == "supplier_admin_group" || role_name.downcase == "customer_admin_group"
  end

  def selected_role_is_available_detail(role_name)
    return true unless role_name.downcase == "superadmin" || role_name.downcase == "supplier" || role_name == "customer" || role_name == "default_user"
  end

  def find_group_for_role(parent)
    if parent.blank?
      result = "No Group"
    else
      if parent.name == "customer"
        result = Company.first.brand_tmp
      else
        result = parent.name
      end
    end
    return result
  end

end
