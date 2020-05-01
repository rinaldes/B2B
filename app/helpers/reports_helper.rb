module ReportsHelper
	def service_level_percentation(supplier_id, po)
		supplier = Supplier.find(po.supplier_id)
    sl = supplier.service_level
    en = supplier.extra_notes.first
    details = po.details_purchase_orders

    unless en.blank?
      en = ExtraNote.find(:all, :conditions=>["en_type ilike ?","%df%"]).first
    end

    if sl.nil?
      default_sl= ServiceLevel.find_by_sl_code("Default")
      if default_sl.nil?
        sl = {:sl_qty=> 30, :sl_line=>30, :sl_time=>40}
      else
        sl = default_sl
      end
    # sum of supplier's service level
      now = Date.today
      time = 0
      if po.received_date > po.due_date
        days = en[:text].split(/[[:alpha:]]/)
        days.each do |day|
          exp = day.to_i if day.to_i != 0
        end
        expired_date = po.due_date + exp
        diff = po.received_date - po.due_date
        time = (exp-diff)/exp
      end
      received_line_total = details.count
      ordered_qty_total = po.details_purchase_orders.count
      ordered_total = 0
      received_total = 0
      details.each do |detail|
        ordered_total =+ detail.order_qty
        received_total =+ detail.received_qty
      end
      qty =(ordered_total - received_total)/ ordered_total
      line =(ordered_qty_total - received_line_total) /ordered_qty_total
      p_line = (1 - line) * sl[:sl_line]
      p_qty = (1 - qty) * sl[:sl_qty]
      p_time = (1- time) * sl[:sl_time]
      total_sl = p_line + p_qty  + p_time

      supplier[:sl_line_total] = p_line
      supplier[:sl_order_total] = p_qty
      supplier[:sl_time_total] = p_time
      supplier[:service_level_total] = total_sl

  		return supplier
  	end
	end

  def filter_path
    case params[:action]
    when "service_level_suppliers"
      "#{service_level_suppliers_reports_path}"
    when "on_going_disputes"
      if params[:type] == "GRN"
        "#{on_going_disputes_reports_path('GRN')}"
      elsif params[:type] == "GRPC"
        "#{on_going_disputes_reports_path('GRPC')}"
      end
    when "pending_deliveries"
      "#{pending_deliveries_reports_path}"
    when "returned_histories"
      "#{returned_histories_reports_path}"
    end
  end
end
