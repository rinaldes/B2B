module OrderToPayments::GoodsReceiveNotesHelper
  def grn_nil_to_unread(po)
  	if po.order_type == "#{GRN}"
      if po.grn_nil?
        po.to_unread_grn if po.can_to_unread_grn?
      end
    end
    state_label_for(po)
  end

  def dispute_grn(p)
  	diff = p.commited_qty.to_i - p.received_qty.to_i
  	return raw(diff)
  end

  def grn_escalated
    grn_dispute_setting = DisputeSetting.find_by_transaction_type('GRN')
    current_level = UserLevelDispute.where("user_id=#{current_user.id} AND dispute_setting_id=#{grn_dispute_setting.id}").last
    PurchaseOrder.where("user_id=#{current_user.id} AND grn_number='#{@grn.grn_number}'").count >= grn_dispute_setting.max_round && UserLevelDispute.where("dispute_setting_id=#{grn_dispute_setting.id} AND level > #{current_level.level}").present?
  end

  def service_level_grn(p)

  end

  def display_grn_state(state)
    str=''
    case state
    when "nil" || "unread" || "read"
    str =''
    when "dispute"
      str =" <span class='label label-large label-important'>#{state}</label>"
    when "rev"
      str = "<span class='label label-large label-pink '>#{state}</label>"
    when "accepted"
      str = "<span class='label label-large label-success '>#{state}</label>"
    end
    return raw(str)
  end

  def display_details_service_level(p)
    if !p.received_qty.to_i.blank? && p.received_qty.to_i > 0
      total = (p.commited_qty.to_i / p.received_qty.to_i)*100
      label = "success"
      unless total == 100
        label = "warning"
      end
      raw("<center><span class='badge badge-#{label}'> #{total}%</span></center>")
    end
  end

  def display_grn_histories(grn_number)
    str = ''
    grns = PurchaseOrder.order("created_at asc").where("grn_number like ? and order_type like ?", "%#{grn_number}%", "%#{GRN}%")

    has_dispute = false
    has_reject = false
    has_accept = false

    grns.each_with_index do |grn, i|
      state = grn.grn_state_name.to_s
      text = state
      link = false

      case state
      when "unread"
        text = "new"
      when "read"
        text = "new"
      when "dispute"
        has_dispute = true
        link = true
      when "rev"
        has_reject = true
        link = true

        count = grn.revision_to if grn.grn_rev?
        unless count.nil?
          text = "Rejected##{count}"
        end
      when "accepted"
        str += "<span class='btn btn-minier history-btn disabled'>dispute</span>" if !has_dispute
        str += "<span class='btn btn-minier history-btn disabled'>rejected</span>" if !has_reject
        has_dispute = true
        has_reject = true
        has_accept = true
        link = true
      end

      label = grn == grns.last ? "primary" : "default"
      row = i < grns.count - 5 ? "?row=#{grns.count - i}" : ""

      str += link ? (link_to text, order_to_payments_get_grn_history_path(grns.last.id) + "#{row}#grn_#{grn.id}", :class => "btn btn-minier btn-#{label} history-btn")
                  : (button_tag text, :class => "btn btn-minier btn-#{label} history-btn", :disabled => "disabled")
    end

    str += "<span class='btn btn-minier history-btn disabled'>dispute</span>" if !has_dispute
    str += "<span class='btn btn-minier history-btn disabled'>rejected</span>" if !has_reject
    str += "<span class='btn btn-minier history-btn disabled'>accepted</span>" if !has_accept

    "<div class='histories-div'>" + str + "</div>"
  end

  def display_history_btn_grn(grn)
    str=''
    rev_count = grn.count_rev_of(grn.order_type)
    unless rev_count.nil?
      if (grn.grn_rev? || grn.grn_dispute?) && can?(:read_grn_history, grn)
        str += link_to "History", order_to_payments_get_grn_history_path(grn.id), :class=> "btn btn-default pull-right"
        str += display_grn_histories(grn.grn_number)
      end
    end
    if grn.grn_accepted?
      str += link_to "History", order_to_payments_get_grn_history_path(grn.id), :class=> "btn btn-default pull-right"
      str += display_grn_histories(grn.grn_number)
    end
    return raw(str)
  end

  def display_remarked_grn_details?(grn,p)
    if grn.grn_dispute? || grn.grn_rev?
      unless grn.po_remark.blank?
        render :partial=> 'row_details', :locals=>{:p=>p}
      end
    else
      render :partial=> 'row_details', :locals=>{:p=>p}
    end
  end

  def grn_dispute_flow_selector(po)
    PurchaseOrder
        .where("po_number = ? AND user_level = ? AND grn_state = 3 AND order_type = ?", po.po_number, po.user_level, GRN)
  end
end
