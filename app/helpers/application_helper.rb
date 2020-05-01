module ApplicationHelper
  private

  def sortable(column, title = nil)
    title ||= column.titleize
    direction = column == params[:sort] && params[:direction] == "asc" ? "desc" : "asc"
    link_to title, :sort => (column rescue 'code'), :direction => direction#, :remote => true
  end

  def is_active?(link_path)
    if Rails.application.routes.recognize_path(link_path)[:controller] == params[:controller]
      #khusus link untuk menu report saja
      if params[:controller] == "reports"
        if link_path.split("/")[2] == params[:action]
          unless link_path.split("/")[3].blank?
            if link_path.split("/")[3] == params[:type]
              "active"
            else
              ""
            end
          else
            "active"
          end
        elsif params[:action] == "on_going_dispute_details"
          if link_path.split("/")[3] == params[:type]
              "active"
          else
            ""
          end
        elsif params[:action] == "returned_history_details"
          if link_path.split("/")[2] == "returned_histories"
            "active"
          else
            ""
          end
        elsif params[:action] == "pending_delivery_details"
          if link_path.split("/")[2] == "pending_deliveries"
            "active"
          else
            ""
          end
        else
          ""
        end
      else
        "active"
      end
    else
      ""
    end
  end

#  def show_alert_success_sign_in
#    html = ""
##    if flash[:notice]
 #     html = "<div class='alert alert-block alert-success'>
 #               <button type='button' class='close' data-dismiss='alert'>
 #                 <i class='icon-remove'></i>
 #               </button>
 #               <i class='icon-ok green'></i>
 #               <strong class='green'>
 #                 #{flash[:notice]}
 #               </strong>
 #             </div>"
 #   end
 #   return html.html_safe
 # end

  def split_controller_name
    params[:controller].split("/")[0]
  end

  def check_tree_menus(controller_name)
    flag = controller_name.split("/")[0]
    user_flag = controller_name.split("/")[1]
    js = ""
    if flag == "order_to_payments"
      js = "<script>
            $('.order').trigger('click');
           </script>"
    elsif user_flag == "users"
      js = "<script>
            $('.user').trigger('click');
           </script>"
    elsif user_flag == "notifications"
      js = "<script>
            $('.user').trigger('click');
           </script>"
    elsif user_flag == "type_of_users"
      js = "<script>
            $('.user').trigger('click');
           </script>"
    elsif user_flag == "user_level_disputes"
      js = "<script>
            $('.user').trigger('click');
           </script>"
    elsif flag == "reports"
      js = "<script>
            $('.reports').trigger('click');
            $($('.submenu2').find()).children().hide()
           </script>"
    elsif flag == "archives"
      js = "<script>
            $('.archive').trigger('click');
            $($('.submenu2').find()).children().hide()
           </script>"
    end
    return js.html_safe
  end

#function for title page based on its controller, it splits current controller name for good name for page title
  def title_page(controller_name)
    raw=controller_name.split(/[_\/]/)
    if raw[0] == "order"
      3.times do |i|
        raw.shift
      end
    end

    if raw[0] == "setting"
      raw.shift
    end

    case params[:action]
    when 'show'
      raw.insert((raw.count + 1), 'detail')
    when "new"
      raw.insert(0, 'new')
    when "edit"
      raw.insert(0, 'edit')
    when "edit_level_limit"
      raw.insert(0, 'change level limit')
    when "get_grn_history"
      raw.insert(0, 'History of')
    when "get_grpc_history"
      raw.insert(0, 'History of')
    when "features"
      raw.insert(0, 'Set Feature')
    when "get_report"
      raw.insert(0, "#{params[:search][:order_type].gsub('_', ' ')} Report")
    when "detail_report_return"
      raw.insert(0, "Detail #{params[:title].gsub('_', ' ')} Report")
    when "detail_report_orders"
      raw.insert(0, "Detail #{params[:title].gsub('_', ' ')} Report")
    when "detail_report_debit_note"
      raw.insert(0, "Detail #{params[:title].gsub('_', ' ')} Report")
    when "service_level_suppliers"
      raw.insert(0, "#{params[:action].gsub('_', ' ')}")
    when "on_going_disputes"
      type = params[:type] == "GRN" ? GRN : GRPC
      raw.insert(0, "#{params[:action].gsub('_', ' ')} (#{type})")
    when "pending_deliveries"
      raw.insert(0, "#{params[:action].gsub('_', ' ')}")
    when "returned_histories"
      raw.insert(0, "#{params[:action].gsub('_', ' ')}")
    when "returned_history_details"
      raw.insert(0, "#{params[:action].gsub('_', ' ')}")
    when "on_going_dispute_details"
      type = params[:type] == "GRN" ? GRN : GRPC
      raw.insert(0, "#{params[:action].gsub('_', ' ')} (#{type})")
    when "pending_delivery_details"
      raw.insert(0, "#{params[:action].gsub('_', ' ')}")
    end

    unless params[:action] == "index"
      temp = raw[-1].singularize
      raw[-1] = temp
    end

    #khusus hanya untuk reporting dashboard
    if params[:controller].downcase == "dashboards" && params[:action] == "get_report"
      title=raw[0].titleize
    elsif params[:controller].downcase == "dashboards" && params[:action] == "detail_report_orders"
      title=raw[0].titleize
    elsif params[:controller].downcase == "dashboards" && params[:action] == "detail_report_debit_note"
      title=raw[0].titleize
    elsif params[:controller].downcase == "dashboards" && params[:action] == "detail_report_return"
      title=raw[0].titleize
    else
      title=raw.join(' ').titleize
    end

    if title == 'Companies' || title == 'Company'
      case params[:action]
        when 'index'
          title = "Company Profile"
        when 'new'
          title = "Create Company Profile"
        when 'edit'
          title = "Edit Company Profile"
      end
    end

    js= "<script>
      $('.title-page').html('#{get_alias_title_name_controller(title)}');
      </script>"
    return js.html_safe
  end
#function for show error validation message on login layout
  def show_error_validation object
    if object.errors.any?
      str=''
      object.errors.full_messages.each do |msg|
        str +="<span class='red'>#{msg}</span>"
      end
      return str
    end
  end

  def show_link_setting_or_dashboards
    if split_controller_name == "setting"
      link_to raw('<i class="icon-home"></i>Dashboards'), dashboards_path || root_path
    else
      link_to raw('<i class="icon-cog"></i>Settings'), setting_users_path
    end
  end

  def show_link_edit_password
    unless current_user.nil?
      link_to raw('<i class="icon-lock"></i>Change Password'), setting_change_password_user_path(current_user), :remote => true, 'data-toggle' =>  "modal", 'data-target' => '#modal-change-password', id: "change-password"
    end
  end
  def show_link_edit_email_notif
    unless current_user.nil?
      link_to raw('<i class="icon-edit"></i>Email Notifications'), change_email_notif_setting_users_path(current_user), :remote => true, 'data-toggle' =>  "modal", 'data-target' => '#modal-change-email-notif', id: "change-email-notif"
    end
  end
#function for showing notification on topbar
  def show_notifications
    unless @sum_notif > 0
      animateornot=""
    else
      animateornot="icon-animated-vertical"
    end
    link_to raw("<i class='icon-envelope-alt icon-only #{animateornot}'></i><span class='badge badge-success'>#{@sum_notif}</span>"), short_notif_path, :remote => true, 'data-toggle' =>  "dropdown", :class=> "dropdown-toggle"
  end

  def show_render_breadcrumb(breadcrumb_name)
    breadcrumb = []
    if split_controller_name == "setting"
      breadcrumb << "<i class='icon-cog'></i>"
    else
      breadcrumb << "<i class='icon-home'></i>"
    end
    breadcrumb << breadcrumb_name
    breadcrumb.join(" ").html_safe
  end

  def convert_date(date)
    new_date = []
    if date
      case date.strftime("%a")
        when "Sun"
          new_date << "Sunday, "
        when "Mon"
          new_date << "Monday, "
        when "Tue"
          new_date << "Tuesday, "
        when "Wed"
          new_date << "Wednesday, "
        when "Thu"
          new_date << "Thursday, "
        when "Fri"
          new_date << "Friday, "
        when "Sat"
          new_date << "Saturday, "
      end
      new_date << date.strftime("%d %B %Y")
    else
      if split_controller_name == "setting"
        new_date << "Not Logged In"
      end
    end
    return new_date.join(' ').html_safe
  end
#function for showing create menu item for respective controller
  def show_create_new_item(controller_name)
    if controller_name.match('/')
      object = controller_name.split('/')
      path = "#{object[1]}/new"
      puts path
    else
      object = controller_name
      path = "#{object}/new"
      puts path
    end

    if controller_name.match('setting')
      #unless page type of users
      unless controller_name.split('/')[1] == "type_of_users" || controller_name.split('/')[1] == "user_logs"
        if can? :create, controller_name.split('/')[1].singularize.to_sym
          str = "<div class='pull-right'>"
          str +=  link_to "<i class='icon-plus'> </i> Create".html_safe, path, :class => 'btn btn-small btn-info'
          str +="</div>"
        end
      end
    else
      if controller_name.match("payment_vouchers")
        if params[:action] == "index" && can?(:create , controller_name.singularize.to_sym)
          str = "<div class='pull-right'>"
          str +=  link_to "<i class='icon-plus'> </i> Generate Payment Voucher".html_safe, path, :class => 'btn btn-small btn-info'
          str +="</div>"
        end
      elsif (controller_name == "payments" && params[:action] == "index") && can?(:create, controller_name.singularize.to_sym)
          str = "<div class='pull-right'>"
          str +=  link_to "<i class='icon-plus'> </i> Create Payment".html_safe, path, :class => 'btn btn-small btn-info'
          str +="</div>"
      end
    end
    return raw(str)
  end

  def last_rp_approval_is_supplier
    GeneralSetting.find_by_desc('Last Return Process Approval').value == 'Supplier' rescue true
  end

  def last_rp_approval_is_customer
    GeneralSetting.find_by_desc('Last RP Approval').value == 'Customer' rescue true
  end

  def show_print_button(controller_name)
    str = ''
    if controller_name.match('/')
      object = controller_name.split('/')
      controller = object[1]
    else
      controller = controller_name
    end
    case "#{controller}"
      when 'purchase_orders','goods_receive_notes','goods_receive_price_confirmations','invoices','advance_shipment_notifications', 'returned_processes'
        str += "<div class='pull-right'>"
        str += link_to "<i class='icon-print'></i> Print".html_safe, new_print_path(controller), :class =>"btn btn-small btn-info", :remote=>true,'data-toggle' => "modal", 'data-target'=> '#new-print', id: "prep-print", :title=>"Print"
        str +=" </div>"
      when 'early_payment_requests'
        str += "<div class='pull-right'>"
        str += link_to "<i class='icon-print'></i> Print".html_safe, print_early_payment_requests_path, :class =>"btn btn-small btn-info", :title=>"Print", :target => "_blank"
        str +=" </div>"
      when 'debit_notes'
        str += "<div class='pull-right'>"
        str += link_to "<i class='icon-print'></i> Print".html_safe, "javascript:void(0)", :onclick => "get_print_debit_notes('#{print_order_to_payments_debit_notes_path}')",:class =>"btn btn-small btn-info", :title=>"Print"
        str +=" </div>"
      else
        str = ''
    end
    return str.html_safe
  end
  def show_synch_now(controller_name)
    if controller_name.match('/')
      object = controller_name.split('/')
      controller = object[1]
    else
      controller = controller_name
    end
    str = ''
    case controller
      when "purchase_orders"
        path = synch_po_now_order_to_payments_purchase_orders_path
        if can?(:synch_po_now, PurchaseOrder)
          str += "<div class='pull-right'>"
          str +=  link_to("<i class=' icon-download-alt'> </i> Sync Now".html_safe, path, :class => 'btn btn-small btn-info', :remote =>true, :id=>"synch-po", :onclick => "add_api_from_po(this)")
          str += "</div>"
        end
      when "goods_receive_notes"
        path = order_to_payments_synch_grn_now_path
        if can?(:synch_grn_now, PurchaseOrder)
          str += "<div class='pull-right'>"
          str +=  link_to("<i class=' icon-download-alt'> </i> Sync Now".html_safe, path, :class => 'btn btn-small btn-info', :remote =>true, :id=>"synch-po", :onclick => "add_api_from_po(this)")
          str += "</div>"
        end
      when "returned_processes"
        path = synch_returned_processes_path
        if can?(:synch, ReturnedProcess)
          str += "<div class='pull-right'>"
          str +=  link_to("<i class=' icon-download-alt'> </i> Sync Now".html_safe, path, :class => 'btn btn-small btn-info', :remote =>true, :id=>"synch-po", :onclick => "add_api_from_return(this)")
          str += "</div>"
        end
      when "suppliers", "suppliers_groups"
        path = synch_suppliers_now_path
        if can?(:synch_suppliers_now, Supplier) && params[:action] == "index"
          str = "<div class='pull-right'>"
          str +=  link_to("<i class=' icon-download-alt'> </i> Sync Now".html_safe, path, :class => 'btn btn-small btn-info', :remote =>true, :id=>"synch-po", :onclick => "add_suppliers_from_api(this)")
          str += "</div>"
        end
      when "warehouses", "warehouses_groups"
        path = synch_warehouses_now_warehouses_path
        if can?(:synch_warehouses_now ,Warehouse) && params[:action] == "index"
          str = "<div class='pull-right'>"
          str +=  link_to("<i class=' icon-download-alt'> </i> Sync Now".html_safe, path, :class => 'btn btn-small btn-info', :remote =>true, :id=>"synch-po", :onclick => "add_warehouses_from_api(this)")
          str += "</div>"
        end
      when "products"
        path = synch_products_now_products_path
        if can? :synch_products_now, Product
          str = "<div class='pull-right'>"
          str +=  link_to("<i class=' icon-download-alt'> </i> Synch Now".html_safe, path, :class => 'btn btn-small btn-info', :remote =>true, :id=>"synch-po", :onclick => "add_products_from_api(this)")
          str += "</div>"
        end
      when "debit_notes"
        path = synch_order_to_payments_debit_notes_path
        if can? :synch, DebitNote
          str = "<div class='pull-right'>"
          str +=  link_to("<i class=' icon-download-alt'> </i> Synch Now".html_safe, path, :class => 'btn btn-small btn-info', :remote =>true, :id=>"synch-po", :onclick => "add_debit_note_from_api(this)")
          str += "</div>"
        end
      else
        str = ""
    end
    return raw(str)
  end

  def export_pdf(controller_name)
    path = ""
    if controller_name.match('/')
      object = controller_name.split('/')
      controller = object[1]
    else
      controller = controller_name
    end
    str = ''
    case controller
      when "suppliers", "suppliers_groups"
        path = generate_pdf_all_sg_url

      when "warehouses", "warehouses_groups"
        path = generate_pdf_all_wg_url

      when "products"
        path = generate_pdf_all_prod_url

      when "purchase_orders"
        path = order_to_payments_generate_pdf_all_po_url

      when "advance_shipment_notifications"
        path = order_to_payments_generate_pdf_all_asn_url

      when "goods_receive_notes"
        path = order_to_payments_generate_pdf_all_grn_url

      when "goods_receive_price_confirmations"
        path = order_to_payments_generate_pdf_all_grpc_url

      when "invoices"
        path = order_to_payments_generate_pdf_all_inv_url

      when "debit_notes"
        path = order_to_payments_generate_pdf_all_dn_url

      when "archive"
        path = order_to_payments_generate_pdf_all_arc_url

      when "returned_processes"
        path = generate_pdf_all_rp_url

      when "payment_vouchers"
        path = generate_pdf_all_pv_url

      when "payments"
        path = generate_pdf_all_pay_url

      when "early_payment_requests"
        path = generate_pdf_all_epr_url

      else
        path = ""
    end
    if params[:action] == "index"
      if path == ""
        str = ""
      else
        str = "<div class='btn-group'>"
        str += link_to "#{image_tag 'PDF-icon.png'}".html_safe, path, :target => "blank"
        str += "</div>"
      end
    end
    return raw(str)
  end

  def export_excel(controller_name)
    path = ""
    if controller_name.match('/')
      object = controller_name.split('/')
      controller = object[1]
    else
      controller = controller_name
    end
    str = ''
    case controller
      when "suppliers", "suppliers_groups"
        path = suppliers_groups_path(:id => params[:id], format: "xls")

      when "warehouses", "warehouses_groups"
        path = warehouses_groups_path(:id => params[:id], format: "xls")

      when "products"
        path = products_path(:id => params[:id], format: "xls")

      when "purchase_orders"
        path = order_to_payments_purchase_orders_path(:id => params[:id], format: "xls")

      when "advance_shipment_notifications"
        path = order_to_payments_advance_shipment_notifications_path(:id => params[:id], format: "xls")

      when "goods_receive_notes"
        path = order_to_payments_goods_receive_notes_path(:id => params[:id], format: "xls")

      when "goods_receive_price_confirmations"
        path = order_to_payments_goods_receive_price_confirmations_path(:id => params[:id], format: "xls")

      when "invoices"
        path = order_to_payments_invoices_path(:id => params[:id], format: "xls")

      when "debit_notes"
        path = order_to_payments_debit_notes_path(:id => params[:id], format: "xls")

      when "returned_processes"
        path = returned_processes_path(:id => params[:id], format: "xls")

      when "payment_vouchers"
        path = payment_vouchers_path(:id => params[:id], format: "xls")

      when "payments"
        path = payments_path(:id => params[:id], format: "xls")

      when "early_payment_requests"
        path = early_payment_requests_path(:id => params[:id], format: "xls")

      else
        path = ""
    end
    if params[:action] == "index"
      if path == ""
        str = ""
      else
        str = "<b>Export</b> :    &nbsp; &nbsp; &nbsp;  "
        str += "<div class='btn-group'>"
        str += link_to "#{image_tag 'Excel-icon.png'}".html_safe, path
        str += "</div>"
      end
    end
    return raw(str)
  end
#function to decide which class alert to use based on flahs type message
  def flash_class(level)
    case level
      when :notice then "alert alert-info"
      when :success then "alert alert-success"
      when :error then "alert alert-error"
      when :alert then "alert alert-alert"
      end
  end
#this is just for its icon
  def flash_icon(level)
    case level
      when :notice then "icon-ok blue"
      when :success then "icon-ok green"
      when :error then "icon-exclamation-sign red"
      when :alert then "icon-warning-sign red "
    end
  end

  def filter_feature_for_super_admin(names)
    if !names.nil?
      names.delete_if {|name| name.match("Devise")}
      return names
    end
  end

  def search_path(controller_name)
    if controller_name.match('setting')
      if controller_name.match('/')
        object=controller_name.split('/')
        path= "#{object[1]}"
      else
        object=controller_name
        path="#{object}"
      end
      return path
    end
  end
  def print_path(controller_name)
    if controller_name.match('/')
      object = controller_name.split('/')
      controller = object[1]
    else
      controller = controller_name
    end

    case controller.downcase
      when "purchase_orders"
        path = print_order_to_payments_purchase_orders_path
      when "debit_notes"
        path = print_order_to_payments_debit_notes_path
    end

    return path
  end

  def label_for(state)

  end

  def show_filter_for_print(controller_name)
    filter_arr = []
    case controller_name
    when "purchase_orders"
      filter_arr = ["Order Number", "Status"]
    when "advance_shipment_notifications"
      filter_arr = ["ASN Number", "Status"]
    when "goods_receive_notes"
      filter_arr = ["GRN Number", "Status"]
    when "goods_receive_price_confirmations"
      filter_arr = ["GRPC Number", "Status"]
    when "invoices"
      filter_arr = ["Proforma Invoice Number", "Status"]
    when "returned_processes"
      filter_arr = ["Return Number", "Order Number", "Invoice Number", "Status"]
    end
    return select("search", "field", filter_arr.collect{|arr| [arr] },{}, :onchange => "get_autocomplete_state('print-list-po','#{controller_name}')")
  end

  def show_filter_by_controller
    if params[:controller].split("/").count == 2
      controller_name = params[:controller].split("/")[1]
    else
      controller_name = params[:controller]
    end

    filter_arr = []
    case controller_name
    when "dashboards"
      if params[:search][:order_type] == "purchase_orders"
        filter_arr = ["Order Number", "Status"]
      elsif params[:search][:order_type] == "goods_receive_notes"
        filter_arr = ["GRN Number", "Status"]
      elsif params[:search][:order_type] == "goods_receive_price_confirmations"
        filter_arr = ["GRPC Number", "Status"]
      elsif params[:search][:order_type] == "invoices"
        filter_arr = ["Invoice Number", "Status"]
      elsif params[:search][:order_type] == "goods_return_note"
        filter_arr = ["Return Number", "Invoice Number", "Status"]
      elsif params[:search][:order_type] == "debit_notes"
        filter_arr = ["Order Number", "Status"]
      end
    when "users"
      filter_arr = ["Email", "Username", "Role", "Name"]
    when "dispute_settings"
      filter_arr = ["Transaction Type", "Max Count", "Time Type"]
    when "roles"
      filter_arr = ["Name", "Group"]
    when "features"
      filter_arr = ["Name", "Regulator"]
    when "products"
      filter_arr = ["Name", "Supplier", "Code"]
    when "suppliers"
      filter_arr = ["Name", "Level", "Code"]
    when "purchase_orders"
      filter_arr = ["Order Number", "Status"]
    when "advance_shipment_notifications"
      filter_arr = ["ASN Number", "Status"]
    when "goods_receive_notes"
      filter_arr = ["GRN Number", "Status"]
    when "goods_receive_price_confirmations"
      filter_arr = ["GRPC Number", "Status"]
    when "invoices"
      filter_arr = ["Invoice Number", "Status"]
    when "debit_notes"
      filter_arr = ["Warehouse Name","Supplier Code","Suffix","Tracking Type","Tracking Number","Order Number", "Reference", "Status"]
    when "notifications"
      filter_arr = ["Title"]
    when "returned_processes"
      filter_arr = ["Return Number", "Invoice Number", "Status"]
    when "service_levels"
      filter_arr= ["Code"]
    when "type_of_users"
      filter_arr= ["Group"]
    when "warehouses"
      filter_arr= ["Name", "Code"]
    when "payment_vouchers"
      if params[:action] == "index"
        filter_arr= ["Voucher", "Supplier Code"]
      else
        filter_arr= ["Supplier Code", "PO Number", "GRN Number", "Invoice Number"]
      end
    when "early_payment_requests"
      filter_arr = ["Invoice Number"]
    when "payments"
      filter_arr = ["Payment No","Warehouse Code", "Supplier Code", "Status"]
    when "suppliers_groups"
      if params[:action] == "index"
        filter_arr = ["Group Code", "Group Name"]
      else
        filter_arr = ["Name", "Code"]
      end
    when "warehouses_groups"
      if params[:action] == "index"
        filter_arr = ["Group Code", "Group Name"]
      else
        filter_arr = ["Name", "Code"]
      end
    when "user_logs"
      filter_arr = ["Username"]
    end
    return select("search", "field", filter_arr.collect{|arr| [arr] },{}, :onchange => "get_autocomplete_state('form_search','#{controller_name}')")
  end

  def show_filter_by_activity_type_only_user_log
    if params[:controller].split("/").count == 2
      controller_name = params[:controller].split("/")[1]
    else
      controller_name = params[:controller]
    end
    arr_act_type = ["#{PO}","#{GRN}","#{GRPC}","#{INV}","#{DN}","#{PV}","#{EPR}","#{GRTN}"]
    if controller_name == "user_logs"
      return select("search", "field_2", arr_act_type.collect{|arr| [arr] },{}, :onchange => "get_autocomplete_state('form_search','#{controller_name}')", :disabled => true)
    end
  end

  def change_state_when_action_of_time(po)
    if po.new?
      today=Date.today
      if today > po.due_date.to_date
        po.expire_po if po.can_expire_po?
        po.save
      end
    else
      existed_asn = PurchaseOrder.where(:order_type => "#{ASN}", :po_number => "#{po.po_number}", :is_published => true).first
      if existed_asn.present?
        asn_date = existed_asn.created_at.to_date.strftime("%Y-%m-%d")
        asn_due_date = existed_asn.due_date.to_date.strftime("%Y-%m-%d")
        if asn_date <= asn_due_date
          order_qty, asn_qty = [],[]
          existed_asn.details_purchase_orders.collect{|d|
            order_qty << d.order_qty.to_i
            asn_qty << d.commited_qty.to_i
          }

          if order_qty.sum > asn_qty.sum
            po.fulfill_po_less if po.can_fulfill_po_less?
          else
            po.fulfill_ontime if po.can_fulfill_ontime?
          end
        else
          order_qty, asn_qty = [],[]
          existed_asn.details_purchase_orders.collect{|d|
            order_qty << d.order_qty.to_i
            asn_qty << d.commited_qty.to_i
          }
          if order_qty.sum < asn_qty.sum
            po.fulfill_po_late_less if po.can_fulfill_po_late_less?
          else
            po.fulfill_late if po.can_fulfill_late?
          end
        end
      end
    end
    state_label_for(po)
  end

  def state_label_for(po)
    if params[:controller].split("/").count == 2
      current_cont = params[:controller].split("/")[1]
    else
      current_cont = params[:controller]
    end
    label=''
    state=''
    case current_cont
      when "purchase_orders"
        state = po.state_name.to_s
        case state
          when "new"
            label="success"
          when "open"
            label = "warning"
          when "on_time"
            label = "info"
          when "on_time_but_less_than_100"
            label = "info"
          when "late"
            label = "yellow"
          when "late_but_less_than_100"
            label = "yellow"
          when "expired"
            label = "important"
          when "cancelled"
            label = "default"
        end
      when "advance_shipment_notifications"
        state = po.asn_state_name.to_s
        case state
          when "unread"
            label = "warning"
          when "read"
            label = "info"
          when "customer_edited"
            label = "pink"
          when "supplier_edited"
            label = "pink"
          when "accepted"
            label = "success"
          when "cancelled"
            label = "cancelled"
        end
      when "invoices"
        state = po.inv_state_name.to_s
        case state
          when "new"
            label="warning"
          when "printed"
            label = "info"
          when "incomplete"
            label = "pink"
          when "rejected"
            label = "pink"
          when "completed"
            label = "purple"
        end
      when "goods_receive_notes", "goods_receive_price_confirmations"
        if current_cont == "goods_receive_notes"
          state = po.grn_state_name.to_s
          #count = po.count_rev_of(po.order_type) if po.grn_rev?
          if state == "rev"
            state = "Rejected#"
            count = po.revision_to if po.grn_rev?
          end
        elsif current_cont == "goods_receive_price_confirmations"
          state = po.grpc_state_name.to_s
          #count= po.count_rev_of(po.order_type) if po.grpc_rev?
          if state == "rev"
            state = "Rejected#"
            count = po.revision_to if po.grpc_rev?
          end
        end
        case state
        when "unread"
          label="yellow"
        when "read"
          label = "default"
        when "dispute"
          label = "important"
        when "pending"
          label = "pink"
        when "accepted"
          label = "success"
        when "rev"
          unless count.nil?
            if count <= 2
              label = "warning"
            else
              label = "pink"
            end
          end
        end
      when "payments"
        state = po.state_name.to_s
        case state
          when "pending"
            label = "yellow"
          when "rejected"
            label = "pink"
          when "approved"
            label = "success"
          when "paid_off"
            label = "info"
        end
      when "reports"
        state = po.state_name.to_s
        case state
          when "pending"
            label = "yellow"
          when "rejected"
            label = "pink"
          when "approved"
            label = "success"
          when "paid_off"
            label = "info"
        end
      when "debit_notes"
        state = po.state_name.to_s
        case state
          when "pending"
            label = "yellow"
          when "disputed"
            label = "important"
          when "rejected"
            label = "pink"
          when "accepted"
            label = "success"
          when "expired"
            label = "important"
        end
      end
      if state.split("_").count > 1
        temp = state.split("_")
        state =  temp.join(" ")
      end

    raw("<span class='label label-large label-#{label}'>#{state}#{count}</span>")
  end

  def count_for_records(objects)
    unless objects.blank?
      if objects.last_page?
        raw("Showing entries #{objects.total_count} of #{objects.total_count}")
      else
        unless objects.total_count.to_i == 0
          last_page = objects.total_count / objects.limit_value
          odd_or_even = objects.total_count % objects.limit_value
          if odd_or_even != 0
            last_page = last_page + 1
          end

          if objects.total_count.to_i < objects.limit_value
            total_entry_until_now = objects.total_count
          else
            unless objects.current_page == last_page
              total_entry_until_now = objects.limit_value + objects.offset_value
            else
              total_entry_until_now = objects.limit_value + objects.offset_value - odd_or_even
            end
          end
          raw("Showing entries #{total_entry_until_now} of #{objects.total_count}")
        else
          raw("Showing entries 0 of #{objects.total_count}")
        end
      end
    end
  end

  #check total count per page and catch modulus
  def total_count(object)
    unless object.blank?
      unless object.total_count.to_i == 0
        tot_per = object.total_count.to_i / object.limit_value.to_i
        tot_mod = object.total_count.to_i % object.limit_value.to_i
        if tot_mod < object.limit_value.to_i
          if tot_mod != 0
            tot_per += 1
          else
            tot_per = tot_mod
          end
        end
      end
      return tot_per
    end
  end

  def make_service_level_right(object)

  end

  def check_included_js_based_on_controller
    if params[:controller].match("/")
      obj = params[:controller].split("/")[1]
    else
      obj = params[:controller]
    end

    if obj.downcase == "purchase_orders"
      javascript_include_tag "order_to_payments/purchase_orders.js"
    elsif obj.downcase == "advance_shipment_notifications"
      javascript_include_tag "order_to_payments/advance_shipment_notifications.js"
    elsif obj.downcase == "goods_receive_notes"
      javascript_include_tag "order_to_payments/goods_receive_notes.js"
    elsif obj.downcase == "goods_receive_price_confirmations"
      javascript_include_tag "order_to_payments/goods_receive_price_confirmations.js"
    elsif obj.downcase == "debit_notes"
      javascript_include_tag "order_to_payments/debit_notes.js"
    elsif obj.downcase == "returned_processes"
      javascript_include_tag "returned_processes"
    end
  end

  def insert_textfield_period
    html = ""
    if params[:controller].split("/").count == 2
      current_cont = params[:controller].split("/")[0]
    else
      current_cont = params[:controller]
    end

    if current_cont.downcase == "order_to_payments"
      html = select_month Date.today, {}, {id: "search_period_1", name: "search[period_1]", style: "width: 127px"}
      html += select_month Date.today, {}, {id: "search_period_2", name: "search[period_2]", style: "width: 127px;margin-left: -3px;"}
      html += select_year Date.today, {start_year: Date.today.year, end_year: 1990}, {id: "search_year", name: "search[year]", style: "width: 77px;"}
    end
    return html
  end

  def wicked_pdf_image_tag_for_barcode(img, options={})
    image_tag "file://#{Rails.root.join('public', img)}", options
  end

  def wicked_pdf_image_tag_for_logo(company, type)
    if company.asset_name.present?
      if File.exists?("#{Rails.root}/public#{company.asset_name_url}")
        wicked_pdf_image_tag(company.asset_name_url(type.to_sym))
      else
        wicked_pdf_image_tag("avatars/avatar2.png")
      end
    else
      wicked_pdf_image_tag("avatars/avatar2.png")
    end
  end

  def state_for_list_po(po)
     case po.order_type
       when "#{PO}"
        state = po.state_name.to_s
      when "#{GRN}"
        state = po.grn_state_name.to_s
      when "#{GRPC}"
        state = po.grpc_state_name.to_s
      when "#{ASN}"
        state = po.asn_state_name.to_s
      when "#{INV}"
        state = po.inv_state_name.to_s
     end
     return state.split('_').join(' ')
  end
  def head_for_list_po(order_type)
    str =''
    case "#{order_type}"
    when "purchase_orders"
      str = "<thead><tr><th>No.</th><th>Order Number</th><th>Order Date</th><th>Due Date</th><th>Total Line</th><th>Total Qty</th><th>Charges Total</th><th>Status</th></tr></thead>"
    when "goods_receive_notes"
      str = "<thead><tr><th>No.</th><th>GRN Number</th><th>Order Date</th><th>Due Date</th><th>Received Date</th><th>Total Line</th><th>Total Qty</th><th>Status</th></tr></thead>"
    when "goods_receive_price_confirmations"
      str ="<thead><tr><th>No.</th><th>GRPC Number</th><th>Order Date</th><th>Due Date</th><th>Received Date</th><th>Sub Total</th><th>Total Tax</th><th>Status</th></tr></thead>"
    when "invoices"
      str = "<thead><tr><th>No.</th><th>Order Number</th><th>Proforma Invoice Number</th><th>Order Date</th><th>Due Date</th><th>Received Date</th><th>Sub Total(Rp)</th><th>Tax(Rp)</th><th>Total(Rp)</th><th>Status</th></tr></thead>"
    when "advance_shipment_notifications"
      str = "<thead><tr><th>No.</th><th>ASN Number</th><th>Order Date</th><th>Due Date</th><th>Total Line</th><th>Ordered Qty</th><th>Commited Qty</th><th>Status</th></tr></thead>"
    when "returned_processes"
      str = "<thead><tr><th>No.</th><th>Return To</th><th>Return From</th><th>Return Number</th><th>Proforma Invoice Number</th><th>Status</th><th>Return Date</status></thead>"
    end
      return str.html_safe
  end
  def body_for_list_po(order_type, results)
    str =''
    cols=0
    if results
      case "#{order_type}"
      when "purchase_orders"
        results.each_with_index do |po, i|
          str += "<tr>
            <td>#{i+1}</td>
            <td>#{po.po_number}</td>
            <td>#{po.po_date.strftime("%d/%m/%Y") if po.po_date.is_a?(Date)}</td>
            <td>#{po.due_date.strftime("%d/%m/%Y") if po.due_date.is_a?Date}</td>
            <td style='text-align:right'>#{po.details_purchase_orders.count}</td>
            <td style='text-align:right'>#{po.total_qty.to_i}</td>
            <td style='text-align:right'>#{total_format(po.order_total, 'Rp.')}</td>
            <td>#{state_for_list_po(po)}</td>
          </tr>"
        end
        cols = 9
      when "goods_receive_notes"
        results.each_with_index do |po, i|
          str += "<tr>
            <td>#{i+1}</td>
            <td>#{po.po_number}</td>
            <td>#{po.po_date.strftime("%d/%m/%Y") if po.po_date.is_a?(Date)}</td>
            <td>#{po.due_date.strftime("%d/%m/%Y") if po.due_date.is_a?Date}</td>
            <td>#{po.received_date.strftime("%d/%m/%Y") if po.received_date.is_a?Date}</td>
            <td style='text-align:right'>#{po.details_purchase_orders.count}</td>
            <td style='text-align:right'>#{po.details_purchase_orders.collect{|d| d.dispute_qty.to_i }.sum}</td>
            <td>#{state_for_list_po(po)}</td>
          </tr>"
        end
        cols = 8
      when "goods_receive_price_confirmations"
         results.each_with_index do |po, i|
          str += "<tr>
            <td>#{i+1}</td>
            <td>#{po.po_number}</td>
            <td>#{po.po_date.strftime("%d/%m/%Y") if po.po_date.is_a?(Date)}</td>
            <td>#{po.due_date.strftime("%d/%m/%Y") if po.due_date.is_a?Date}</td>
            <td>#{po.received_date.strftime("%d/%m/%Y") if po.received_date.is_a?Date}</td>
            <td style='text-align:right'>#{total_format(po.received_total, 'Rp.')}</td>
            <td style='text-align:right'>#{total_format(po.ordered_tax_amt, 'Rp.')}</td>
            <td>#{state_for_list_po(po)}</td>
          </tr>"
        end
         cols=8
      when "invoices"
        results.each_with_index do |po, i|
          str += "<tr>
            <td>#{i+1}</td>
            <td>#{po.po_number}</td>
            <td>#{po.invoice_number}</td>
            <td>#{po.po_date.strftime("%d/%m/%Y") if po.po_date.is_a?(Date) }</td>
            <td>#{po.due_date.strftime("%d/%m/%Y") if po.due_date.is_a?Date}</td>
            <td>#{po.received_date.strftime("%d/%m/%Y") if po.received_date.is_a?Date}</td>
            <td style='text-align:right'>#{total_format(po.received_total,'Rp.')}</td>
            <td style='text-align:right'>#{total_format(po.ordered_tax_amt,'Rp.')}</td>
            <td style='text-align:right'>#{total_format(po.charges_total,'Rp.')}</td>
            <td>#{state_for_list_po(po)}</td>
          </tr>"
        end
         cols=10
      when "advance_shipment_notifications"
        results.each_with_index do |po, i|
          str += "<tr>
            <td>#{i+1}</td>
            <td>#{po.po_number}</td>
            <td>#{po.po_date.strftime("%d/%m/%Y") if po.po_date.is_a?(Date) }</td>
            <td>#{po.due_date.strftime("%d/%m/%Y") if po.due_date.is_a?Date}</td>
            <td style='text-align:right'>#{po.details_purchase_orders.count}</td>
            <td style='text-align:right'>#{count_total_ordered_qty(po).to_i}</td>
            <td style='text-align:right'>#{count_total_commited_qty(po).to_i}</td>
            <td>#{state_for_list_po(po)}</td>
          </tr>"
        end
         cols=8
      when "returned_processes"
        results.each_with_index do |rp, i|
          str += "<tr>
            <td>#{i+1}</td>
            <td>#{rp.purchase_order.supplier.name}</td>
            <td>#{rp.purchase_order.warehouse.warehouse_name }</td>
            <td>#{rp.rp_number}</td>
            <td>#{rp.purchase_order.invoice_number}</td>
            <td>#{rp.state_name.to_s}</td>
            <td>#{rp.rp_date.strftime("%d/%m/%Y")}</td>
          </tr>"
        end
         cols=7
      end

    else
      str ="<tr>
          <td colspan='#{cols}'><center><span class='red'>No match data</span></center></td>
        </tr>"
    end

    return str.html_safe
  end
  def total_format(price, unit=nil)
     return number_to_currency(price, :unit => unit, :separator => ",", :delimiter => ".") if !price.nil?
     return "-" if price.nil?
  end
  def count_total_commited_qty(po)
    count = 0
    po.details_purchase_orders.select("commited_qty").each do |d|
      count += d.commited_qty.to_i
    end
    return count
  end
  def count_total_ordered_qty(po)
    count = 0
    po.details_purchase_orders.select("order_qty").each do |d|
      count += d.order_qty.to_i
    end
    return count
  end

  def get_addresses(obj)
    str = ["<ul class='unstyled spaced'>"]
    obj.addresses.each_with_index do |a, i|
      str << "<li><i class='icon-check blue' style='margin-left: 17px;'> </i><span style='width: 450px'> "
      str << "Address ##{i+1} : #{a.name} #{a.street} #{a.suburb}, #{a.postcode.present?? ',' : ''} #{a.country}"
      str << "</span></li>"
    end
    str << "</ul>"
    str.join(" ").squish.html_safe
  end

  def get_alias_title_name_controller(title_name)
    str = ""
    if title_name == "#{PO}".pluralize
      str = title_name + " (PO) "
    elsif title_name == "#{ASN}".pluralize
      str = title_name + " (ASN) "
    elsif title_name == "#{GRN}".pluralize
      str = title_name + " (GRN) "
    elsif title_name == "#{GRPC}".pluralize
      str = title_name + " (GRPC) "
    elsif title_name == "#{DN}".pluralize
      str = title_name + " (DN) "
    elsif title_name == "Returned Processes"
      str = title_name + " (GRTN) "
    elsif title_name == "Returned Processes Detail"
      str = "Return Process Detail"
    else
      str = "#{title_name}"
    end
    str
  end

  def show_transaction_number(act)
    flag = ""
    case act.transaction_type
    when "#{PO}"
      flag = act.log.po_number
    when "#{GRN}"
      flag = act.log.grn_number
    when "#{GRPC}"
      flag = act.log.grpc_number
    when "#{INV}"
      flag = act.log.invoice_number
    when "#{DN}"
      flag = act.log.order_number
    when "#{PV}"
      flag = act.log.try(:voucher)
    when "Return Process"
      flag = act.log.rp_number
    when "#{EPR}"
      flag = act.log.purchase_order.po_number
    end
    flag
  end

  def show_image_logo(company, type)
    if company.asset_name.present?
      if File.exists?("#{Rails.root}/public#{company.asset_name_url}")
        image_tag(@company.asset_name_url(type.to_sym))
      else
        image_tag "avatars/avatar2.png"
      end
    else
      image_tag "avatars/avatar2.png"
    end
  end

  def is_disputed?(obj)
    count = 0
    unless obj.instance_of?(ReturnedProcess)
      case obj.order_type
        when "#{GRN}"
          count = PurchaseOrder.where(:grn_number => "#{obj.grn_number}").where("grn_state in (3,4,5) AND order_type = '#{GRN}'").count
        when "#{GRPC}"
          count = PurchaseOrder.where(:grpc_number => "#{obj.grpc_number}").where("grpc_state in (3,4,5) AND order_type = '#{GRPC}'").count
        else
      end
    else
      count = ReturnedProcess.where(:rp_number => "#{obj.rp_number}").where("state in (4,5,6)").count
    end

    if count > 1
      return true
    else
      return false
    end
  end

  def mycompany
    return Company.first.brand_tmp
  end

  def background_type
    return GeneralSetting.where(desc: 'Background Type').first.value
  end

  def background
    if GeneralSetting.where(desc: 'Background Type').first.value == 'Colour'
      return GeneralSetting.where(desc: 'Background Color').first.value
    else
      return GeneralSetting.where(desc: 'Background Image').first.background_image
    end
  end

  def title
    return GeneralSetting.where(:desc => "Login Title").first.value rescue nil
  end

  def can_access_setting_menu?
    can?(:read, User) && !current_user.warehouse.blank? || (!current_user.roles.blank? && current_user.roles.first.group_flag ) || current_user.has_role?(:superadmin)
  end

  def is_supplier_group?
    return current_user.try(:supplier).try(:group) && current_user.roles.first.try(:group_flag)
  end

  def is_warehouse_group?
    return current_user.warehouse.group && current_user.roles.first.group_flag
  end

  def is_current_superadmin?
    current_user.has_role? :superadmin
  end
end
