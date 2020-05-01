module OrderToPayments::InvoicesHelper

  def unlock_inv?(po)
    if po.order_type == "#{INV}"
      if po.inv_nil?
        po.to_unlock_inv if po.can_to_unlock_inv?
      end
    end
    state_label_for(po)
  end

  def display_npwp(npwp)
  	str=''
  	split = npwp.split("")
  	split.each_with_index do |np,i|
      str += "#{np}"
      case i
        when 2
        	str +="."
        when 6
        	str += "."
        when 10
        	str += "."
      end
  	end
  	return str
  end

  def check_incompleted_push_invoice(inv)
    flag = false
    if !inv.is_completed_invoice_to_api || inv.details_purchase_orders.collect{|det| det.is_completed_invoice_to_api }.include?(false)
      flag = true
    end
    return flag
  end

  def display_inv_histories(inv_number)
    str = ''
    invs = PurchaseOrder.where(invoice_number: inv_number).order("created_at ASC")
    invs.each_with_index do |inv, i|
      state = inv.inv_state.to_i
      link = false
      case state
      when 1
        text = "new"
      when 2
        text = "printed"
      when "3"
        text = "rejected"
      when 4
        text = "incomplete"
      when 5
        text = "completed"
      end

      label = inv == invs.last ? "primary" : "default"
      row = i < invs.size - 5 ? "?row=#{invs.size - i}" : ""

      str += link ? (link_to text, order_to_payments_get_inv_history_path(invs.last.id) + "#{row}#inv_#{inv.id}", :class => "btn btn-minier btn-#{label} history-btn")
                  : (button_tag text, :class => "btn btn-minier btn-#{label} history-btn", :disabled => "disabled")
    end

    "<div class='histories-div'>" + str + "</div>"
  end

   def display_history_btn_inv(inv)
    str=''
    rev_count = inv.count_rev_of(inv.order_type)
    str += link_to "History", order_to_payments_get_inv_history_path(inv.id), :class=> "btn btn-default pull-right"
    str += display_inv_histories(inv.invoice_number)
    return raw(str)
  end
end