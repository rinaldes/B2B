module OrderToPayments::DebitNotesHelper
  def dn_no_max_round
    current_user.supplier.present? && DebitNote.where("user_id=#{current_user.id} AND order_number='#{@debit_note.order_number}'").count < DisputeSetting.find_by_transaction_type('Debit Note').max_round
  end

  def dn_escalated
    dn_dispute_setting = DisputeSetting.find_by_transaction_type('Debit Note')
    current_level = UserLevelDispute.where("user_id=#{current_user.id} AND dispute_setting_id=#{dn_dispute_setting.id}").last
    DebitNote.where("user_id=#{current_user.id} AND order_number='#{@debit_note.order_number}'").count >= dn_dispute_setting.max_round && UserLevelDispute.where("dispute_setting_id=#{dn_dispute_setting.id} AND level > #{current_level.level}").present?
  end

  def show_button_on_action(debit_note)
    show_action = []
    if can?(:get_dispute_debit_note, :debit_note)
      path = "#{dispute_take_action_order_to_payments_debit_note_path(debit_note,"")}"
      show_action << (link_to "Dispute", "javascript:void(0)", :class => "btn btn-success", :onclick => "getTakeAction(this)", :text => "dispute", :location => "#{path}", :data => { :confirm => "confirm dispute?" })
    end

    # if debit_note.can_revision?  && can?(:get_revision_debit_note, :debit_note)
    #   path = "#{revision_take_action_order_to_payments_debit_note_path(debit_note,"")}"
    #   show_action << (link_to "Revisi", "javascript:void(0)", :class => "btn btn-info", :onclick => "getTakeAction(this)", :text => "revision", :location => "#{path}")
    # end

    if debit_note.can_accept? && can?(:get_accept_debit_note, :debit_note)
      path = "#{accept_take_action_order_to_payments_debit_note_path(debit_note,"")}"
      show_action << (link_to "Accept", "javascript:void(0)", :class => "btn btn-info", :onclick => "getTakeAction(this)", :text => "accept", :location => "#{path}", :data => { :confirm => "confirm accept?" })
    end


    if debit_note.can_reject? && can?(:get_reject_debit_note, :debit_note)
      path = "#{reject_take_action_order_to_payments_debit_note_path(debit_note,"")}"
      show_action << (link_to "Reject", "javascript:void(0)", :class => "btn btn-pink", :onclick => "getTakeAction(this)", :text => "reject", :location => "#{path}", :data => { :confirm => "confirm reject?" })
    end

    show_action.join(" ").html_safe
  end

  def role_has_access_dn
    supplier = current_user.supplier
    disputed_or_pending = @debit_note.disputed? || @debit_note.waiting_approval?
    current_user.roles.first.name.casecmp("superadmin") == 0 || last_dn_approval_is_customer && supplier.nil? && disputed_or_pending || supplier.present? && !disputed_or_pending
  end

  def last_dn_approval_is_customer
    GeneralSetting.where(desc: "Last DN Approval").first.value == "Customer"
  end

  def display_remarked_dn_details?(dn,p)
    if dn.disputed?# || dn.dn_rev?
      render :partial=> 'row_details', :locals=>{:dn=>p} unless dn.dn_remark.blank?
    else
      render :partial=> 'row_details', :locals=>{:dn=>p}
    end
  end

  def show_status_dn(state_name, _count)
    str = ""
    if state_name.to_s.downcase == "revisioned"
      str = "#{state_name.capitalize} ##{_count}"
    else
      str = state_name.to_s.capitalize
    end
    str
  end

  def display_dn_histories(dnote)
    str = ''
    dns = DebitNote.order("created_at asc").where("order_number like ?", "%#{dnote.order_number}%")
    rev = 1

    has_dispute = false
    has_reject = false
    has_accept = false

    dns.each do |dn|
      state = dn.state_name.to_s
      text = state

      case state
      when "pending"
        text = "new"
      when "disputed"
        has_dispute = true
      when "rejected"
        has_reject = true
      when "accepted"
        str += "<span class='btn btn-minier history-btn disabled'>dispute</span>" if !has_dispute
        str += "<span class='btn btn-minier history-btn disabled'>rejected</span>" if !has_reject

        has_dispute = true
        has_reject = true
        has_accept = true
      when "revisioned"
        has_dispute = true
        has_reject = true

        text = show_status_dn(dn.state_name, rev)
        rev += 1
      end

      label = dn == dns.last ? "primary" : "default"
      str += link_to text, order_to_payments_get_dn_history_path(dnote) + "#dn_#{dn.id}", :class => "btn btn-minier btn-#{label} history-btn"
    end

    str += "<span class='btn btn-minier history-btn disabled'>dispute</span>" if !has_dispute
    str += "<span class='btn btn-minier history-btn disabled'>rejected</span>" if !has_reject
    str += "<span class='btn btn-minier history-btn disabled'>accepted</span>" if !has_accept

    "<div class='histories-div'>" + str + "</div>"
  end

  def display_history_btn_dn(dn)
    str=''
    #  rev_count = dn.count_rev_of(dn.order_type)
    # unless rev_count.nil?
       # if (dn.dn_rev? || dn.dn_dispute?) && can?(:read_grn_history, dn)
        str += link_to "History", order_to_payments_get_dn_history_path(dn.id), :class=> "btn btn-default pull-right"
        str += display_dn_histories(dn)
       # end
    # end
    # if grn.grn_accepted?
    #   str = link_to "History", order_to_payments_get_grn_history_path(grn.id), :class=> "btn btn-default pull-right"
    # end
    return raw(str)
  end

  def dn_dispute_flow_selector(po)
    DebitNote.where("order_number = ? AND user_level = ? AND state = 4", po.order_number, po.user_level)
  end
end
