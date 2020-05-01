module Setting::UsersHelper
  def role_names(roles)
    if roles.collect(&:name).join(",").match("_")
      roles.collect(&:name).join(",").gsub("_", " ").capitalize if roles
    else
      roles.collect(&:name).join(",").capitalize if roles
    end
  end

  def convert_status(flag)
    if flag
      "<span class='label label-large label-success'>Activated</span>".html_safe
    else
      "<span class='label label-large label-important'>Inactive</span>".html_safe
    end
  end

  def convert_login(user)
    status = User.find(user.id).signed
    if status == 1
      link_to"<span class='label label-large label-success'>Login</span>".html_safe, force_logout_setting_users_path(:id => user.id, :format => :post)
    else
      "<span class='label label-large label-important'>Logout</span>".html_safe
    end
  end

  def active_non_active_user(user)
    if can? :change_activation, :user
      str ="<div class='pull-left'>"
      str +=  link_to "<i class='icon-user'> </i> #{user.is_activated ? 'Non Active' : 'Active'}".html_safe, setting_change_activation_path(user), :class => 'btn btn-small btn-info', :method => "PUT"
      str +="</div>"
      str.html_safe
    end
  end

  def show_data_supplier_or_warehouse(user)
    value = ""
    label = ""
    if !user.roles.blank? && user.roles.first.group_flag
      if user.supplier.present?
        value = user.supplier.group.name rescue "No Group Supplier"
        label = "Group Supplier "
      elsif user.warehouse.present?
        value = user.warehouse.group.name rescue "No Group Warehouse"
        label = "Group Warehouse"
      end
    else
      if user.supplier
        value = user.supplier.name rescue "No Supplier"
        label = "Supplier"
      else
        value = user.warehouse.warehouse_name rescue "No Warehouse"
        label = "Warehouse"
      end
    end

    text = "
      <li>
        <i class='icon-caret-right blue'></i>
        <span>#{label}</span>
        : <strong>#{value}</strong>
      </li>".html_safe
  end

  def group_user(type_of_users, id=nil)
    _arr_tou = []
    if !current_user.roles.blank? && current_user.roles.first.group_flag
      str = "<span><strong>#{current_user.type_of_user.description}</strong></span>"
      str += hidden_field_tag "group_user", current_user.type_of_user.id
      return str.html_safe
    else
      type_of_users.collect{|tou|
        if tou.description.downcase == "supplier"
          _arr_tou << tou
        else
          _arr_tou << tou
        end
      }
      if id.nil?
        return select_tag("group_user", options_from_collection_for_select(_arr_tou, "id", "description"), :onchange => "show_list_supplier(this.value)")
      else
        return select_tag("group_user", options_from_collection_for_select(_arr_tou, "id", "description","#{id}"), :onchange => "show_list_supplier(this.value)")
      end
    end
  end

  def get_button_feature_by_user(user)
    # features diganti jadi role-based
    return

    if can? :features, :user
      if current_user.has_role?("superadmin") || !user.roles.first.group_flag #group admin tidak bisa merubah featurenya sendiri. harus dirubah oleh superadmin
        str ="<div class='pull-left' style='margin-left: 8px;'>"
        str +=  link_to "<i class='icon-cog'> </i> Change Features".html_safe, features_setting_user_path(user), :class => 'btn btn-small btn-info'
        str +="</div>"
        str.html_safe
      end
    end
  end

  def display_user_features(controller)
    #skarang ini di false dulu, karena feature skrg berdasarkan role, bukan user lagi.
    return

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
      str += check_box_tag 'user[feature_ids][]', feature.id, @user.features.include?(feature), :class => ''
      if feature.name == "Create revise disputed grpc"
        str += "<span class='lbl'> Create Reject grpc</span>"
      elsif feature.name == "Create revise dispute grn"
        str += "<span class='lbl'> Create Reject grn</span>"
      else
        str += "<span class='lbl'> #{feature.name}</span>"
      end
      str += "</td></tr>"
    end
    str += "</table>"
    return str
  end

  def find_group_for_user(name)
    if name == 'Customer'
      result = Company.first.brand_tmp
    else
      result = name
    end
    return result
  end

  def find_path_supplier_or_warehouse(act, u_id, type)
    path = ""
    if act == "select_supplier_or_warehouse"
      path = "/setting/select_supplier_or_warehouse/#{type}"
    else
      path = "users/mutation/#{u_id}"
    end
  end
end
