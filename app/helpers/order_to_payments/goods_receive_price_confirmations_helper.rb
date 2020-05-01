module OrderToPayments::GoodsReceivePriceConfirmationsHelper
  def grpc_nil_to_unread(po)
    if po.order_type == "#{GRPC}"
      if po.grpc_nil?
        po.to_unread_grpc if po.can_to_unread_grpc?
      end
    end
    state_label_for(po)
  end

  def last_grpc_approval_is_customer
    GeneralSetting.where(:desc => "Last GRPC Approval").first.value == "Customer"
  end

  def role_has_access
    supplier = current_user.supplier
    disputed_or_pending = @grpc.grpc_dispute? || @grpc.grpc_pending?
    current_user.roles.first.name.casecmp("superadmin") == 0 || last_grpc_approval_is_customer && supplier.nil? && disputed_or_pending || supplier.present? && !disputed_or_pending
  end

  def grpc_escalated
    grpc_dispute_setting = DisputeSetting.find_by_transaction_type('GRPC')
    current_level = UserLevelDispute.where("user_id=#{current_user.id} AND dispute_setting_id=#{grpc_dispute_setting.id}").last
    PurchaseOrder.where("user_id=#{current_user.id} AND grpc_number='#{@grpc.grpc_number}'").count >= grpc_dispute_setting.max_round && UserLevelDispute.where("dispute_setting_id=#{grpc_dispute_setting.id} AND level > #{current_level.level}").present?
  end

  def no_max_round
    current_user.supplier.present? && PurchaseOrder.where("user_id=#{current_user.id} AND grpc_number='#{@grpc.grpc_number}'").count < DisputeSetting.find_by_transaction_type('GRPC').max_round
  end

  def display_grpc_state(state)
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

  def display_grpc_histories(grpc_number)
    str = ''
    grpcs = PurchaseOrder.order("updated_at asc").where("grpc_number like ? and order_type like ?", "%#{grpc_number}%", "%#{GRPC}%")

    has_dispute = false
    has_reject = false
    has_accept = false

    grpcs.each_with_index do |grpc, i|
      state = grpc.grpc_state_name.to_s
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

        count = grpc.revision_to if grpc.grpc_rev?
        unless count.nil?
          text = "Rejected##{count}"
        end
      when "accepted"
        str += "<span class='btn btn-minier history-btn disabled'>dispute</span>" if !has_dispute
        str += "<span class='btn btn-minier history-btn disabled'>rejected</span>" if !has_reject
        has_accept = true
        link = true
      end

      label = grpc == grpcs.last ? "primary" : "default"
      row = i < grpcs.count - 5 ? "?row=#{grpcs.count - i}" : ""

      str += link ? (link_to text, order_to_payments_get_grpc_history_path(grpcs.last.id) + "#{row}#grpc_#{grpc.id}", :class => "btn btn-minier btn-#{label} history-btn")
                  : (button_tag text, :class => "btn btn-minier btn-#{label} history-btn", :disabled => "disabled")
    end

    str += "<span class='btn btn-minier history-btn disabled'>accepted</span>" if !has_accept

    "<div class='histories-div'>" + str + "</div>"
  end

  def display_history_btn_grpc(grpc)
    str = ''
    rev_count = grpc.count_rev_of(grpc.order_type)
    unless rev_count.nil?
      if (grpc.grpc_rev? || grpc.grpc_dispute?) && can?(:read_grpc_history, grpc)
        str += link_to "History", order_to_payments_get_grpc_history_path(grpc.id), :class=> "btn btn-default pull-right"
        str += display_grpc_histories(grpc.grpc_number)
      end
    end
    if grpc.grpc_accepted?
      str += link_to "History", order_to_payments_get_grpc_history_path(grpc.id), :class=> "btn btn-default pull-right"
      str += display_grpc_histories(grpc.grpc_number)
    end
    return raw(str)
  end

  def display_remarked_grpc_details?(grpc,p)
    if grpc.grpc_dispute? || grpc.grpc_rev?
      unless grpc.po_remark.blank?
        render :partial=> 'row_details', :locals=>{:p=>p}
      end
    else
      render :partial=> 'row_details', :locals=>{:p=>p}
    end
  end

  def grpc_dispute_flow_selector(po)
    PurchaseOrder
        .where("grpc_number = ? AND user_level = ? AND grpc_state = 3 AND order_type = ?", po.grpc_number, po.user_level, GRPC)
  end
end
