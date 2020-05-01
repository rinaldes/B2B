module DashboardsHelper
  def display_select_stats
  	str = "
     <div class='btn-group pull-right'>
		<button class='btn'>Select</button> <button data-toggle='dropdown' class='btn dropdown-toggle'  id='select-po-stats'><span class='caret'></span></button>
		    <ul class='dropdown-menu'>
			<li>"
  	str += link_to 'Purchase Orders', get_po_stats_dashboards_path("#{PO}",''), :class=> 'select_po_stats pull-left', :id=> 'po_stats', :onclick=>'get_stats_for(this)',:remote=>true
  	str +="</li>"
  	str	+= "<li>"
  	str += link_to 'Goods Receive Notes', get_po_stats_dashboards_path("#{GRN}",''), :class=> 'select_po_stats pull-left', :id=> 'grn_stats', :onclick=>'get_stats_for(this)',:remote=>true
  	str	+="	</li>"
  	str += "<li>"
  	str += link_to 'Goods Receive Price Confirmations', get_po_stats_dashboards_path("#{GRPC}",''), :class=> 'select_po_stats pull-left', :id=> 'gprc_stats', :onclick=>'get_stats_for(this)',:remote=>true
  	str +="</li>"
  	str += "<li>"
  	str += link_to 'Invoices', get_po_stats_dashboards_path("#{INV}",''), :class=> 'select_po_stats pull-left', :id=> 'inv_stats', :onclick=>'get_stats_for(this)',:remote=>true
  	str += "</li>"
  	str += "<li>"
  	str += link_to 'Goods Returns', get_po_stats_dashboards_path("#{GRTN}",''), :class=> 'select_po_stats pull-left', :id=> 'grtn_stats', :onclick=>'get_stats_for(this)',:remote=>true
  	str += "</li>"
    str += "<li>"
    str += link_to 'Debit Notes', get_po_stats_dashboards_path("#{DN}",''), :class=> 'select_po_stats pull-left', :id=> 'dn_stats', :onclick=>'get_stats_for(this)',:remote=>true
    str += "</li>"
  	str +="</ul></div>"
  	return str.html_safe
  end

  def get_permision_show_graph
    return (can? :report_purchase_order, :dashboard) || (can? :report_goods_receive_notes, :dashboard) || (can? :report_goods_receive_price_confirmations, :dashboard) || (can? :report_invoice, :dashboard) || (can? :report_goods_return_note, :dashboard) || (can? :report_goods_return_note, :dashboard)
  end

  def display_select_stats_2
    arr = []
    if can? :report_purchase_order, :dashboard
      arr << ["#{PO}","#{PO}"]
    end
    if can? :report_goods_receive_notes, :dashboard
      arr << ["#{GRN}","#{GRN}"]
    end
    if can? :report_goods_receive_price_confirmations, :dashboard
      arr << ["#{GRPC}","#{GRPC}"]
    end
    if can? :report_invoice, :dashboard
      arr << ["#{INV}","#{INV}"]
    end
    if can? :report_goods_return_note, :dashboard
      arr << ["#{GRTN}","#{GRTN}"]
    end
    if can? :report_goods_return_note, :dashboard
      arr << ["#{DN}","#{DN}"]
    end

  	str  = "<div class='pull-right' id='select-stats'>"
    str += "<div class='input-group input-group-sm'>"
    str += "<input type='text' id='datepicker' class='form-control' placeholder='Filter Date' value='#{Time.now.strftime('%Y-%m')}' />"
    str += "</div>"
    str += "</div>"

    return str.html_safe
  end

  def display_service_supplier
    if current_user.has_role?(:superadmin)
      wh = Warehouse.all(:select => "id, warehouse_name")
      supp = Supplier.all(:select => "id, name")
      str  = "<div class='pull-right' id='select-ss'>"
      str += "<span style='position: relative;top:-4px;'>Warehouse : </span>"
      str += select_tag(:warehouse, options_for_select(wh.collect{|wh| [wh.warehouse_name, wh.id] }), prompt: "Select Warehouse", :id => "select_warehouse", :onchange=>"get_service_level_by_supplier(this.value, 'wh', '#{get_suppliers_dashboards_path}')", :style => "width: 18em;margin-left:10px;margin-right:10px;")
      str += "<span style='position: relative;top:-4px;'>Supplier: </span> "
      str += "<span class='sp_select_supp'>"
      str += select_tag(:supplier, options_for_select([]), prompt: "Select Supplier", :id => "select_supplier", :onchange=>"get_service_level_by_supplier(this.value, 'supp', '/dashboards/get_service_level_flot_by_supplier/')", :style => "width: 18em;margin-left:10px;margin-right:10px;")
      str += "</span>"
      str += "</div>"
    elsif current_user.warehouse.present?
      if current_user.roles.last.group_flag
        wh = current_user.warehouse.group.warehouses.collect{|wh| [wh.warehouse_name, wh.id] }
        str = "<div class='pull-right' id='select-ss'>"
        str += "<span style='position: relative;top:-4px;'>Warehouse : </span>"
        str += select_tag(:warehouse, options_for_select(wh), prompt: "Select Warehouse", :id => "select_warehouse", :onchange => "get_service_level_by_supplier(this.value, 'wh', '#{get_suppliers_dashboards_path}')", :style => "width: 18em;margin-left:10px;margin-right:10px;")
        str += "<span style='position: relative;top:-4px;'>Supplier : </span>"
        str += "<span class='sp_select_supp'>"
        str += select_tag(:supplier, options_for_select([]), prompt: "Select Supplier", :id => "select_supplier", :onchange => "get_service_level_by_supplier(this.value, 'supp', '/dashboards/get_service_level_flot_by_supplier/')", :style => "width: 18em;margin-left:10px;margin-right:10px;")
        str += "</span>"
        str += "</div>"
      else
        current_wh = current_user.warehouse
        supp = PurchaseOrder.where(:warehouse_id => current_wh.id, :is_history => false).collect{|po| [po.supplier.name, po.supplier_id]}.uniq
        str = "<div class='pull-right' id='select-ss'>"
        str += "<span style='position: relative;top:-4px;'>Supplier : </span>"
        str += select_tag(:supplier, options_for_select(supp), prompt: "Select Supplier", :id => "select_supplier", :onchange => "get_service_level_by_supplier(this.value, 'supp', '/dashboards/get_service_level_flot_by_supplier/')", :style => "width: 18em;margin-left:10px;margin-right:10px;")
        str += "</div>"
      end
    elsif current_user.supplier.present?
      if current_user.roles.last.group_flag
        supp = current_user.supplier.group.suppliers.collect{|sup| [sup.name, sup.id] }
        str = "<div class='pull-right' id='select-ss'>"
        str +=  "<span style='position: relative;top:-4px;'>Supplier : </span>"
        str += select_tag(:supplier, options_for_select(supp), prompt: "Select Supplier", :id => "select_supplier", :onchange => "get_service_level_by_supplier(this.value, 'supp','/dashboards/get_service_level_flot_by_supplier/')", :style => "width: 18em;margin-left:10px;margin-right:10px;")
        str += "</div>"
      else
        current_supp = current_user.supplier.id
        str = "<div class='pull-right' id='select-ss'>"
        str += hidden_field_tag :supplier, current_user.supplier.id, :id => "select_supplier"
        str += "<span style='position: relative;top:-4px;'>Supplier :  <strong>#{current_user.supplier.name}</strong> </span>"
        str += "</div>"
      end
    end

    return str.html_safe
  end

  def is_warehouse_and_admin?
    return current_user.has_role?("superadmin") || (current_user.warehouse.present? && current_user.roles.first.group_flag)
  end
end
