module ReturnedProcessesHelper
  def role_has_access_rp
    supplier = current_user.supplier
    disputed_or_pending = @retur.disputed? || @retur.pending?
    current_user.roles.first.name.casecmp("superadmin") == 0 || last_rp_approval_is_customer && supplier.nil? && disputed_or_pending || supplier.present? && !disputed_or_pending
  end

  def rp_no_max_round
    current_user.supplier.present? && ReturnedProcess.where("user_id=#{current_user.id} AND rp_number='#{@retur.rp_number}'").count < DisputeSetting.find_by_transaction_type('Return Process').max_round
  end

  def rp_escalated
    dspt_stng = DisputeSetting.find_by_transaction_type('Return Process')
    lv = UserLevelDispute.where("user_id=#{current_user.id} AND dispute_setting_id=#{dspt_stng.id}").last.level
    ReturnedProcess.where("user_id=#{current_user.id} AND rp_number='#{@retur.rp_number}'").count >= dspt_stng.max_round && UserLevelDispute.where("dispute_setting_id=#{dspt_stng.id} AND level > #{lv}").present?
  end

  def nil_to_unread(retur)
  	if retur.nil?
  	  retur.to_unread
    end
    return state_label_retur(retur)
  end
  def state_label_retur(retur)
    state = retur.state_name.to_s
    label = ''
    count = ''
    case state
    when 'unread'
      label = 'yellow'
    when 'read'
      label = 'default'
    when 'received'
      label ='info'
    when 'disputed'
      label ='important'
    when 'rev'
      #count = retur.count_rev_of_retur
      count = retur.revision_to if retur.rev?
      unless count.nil?
      	if count <= 2
      	  label = 'warning'
      	else
      	  label = 'pink'
      	end
      end
      state = "Revision#"
     when 'accepted'
       label = 'success'
    end
    return raw("<span class='label label-large label-#{label}'>#{state}#{count}</span>")
  end

  def display_remarked_retur_details?(retur,p)
    if retur.disputed? || retur.rev?
      unless retur.remark.blank?
        render :partial=> 'row_details', :locals=>{:p=>p}
      end
    else
      render :partial=> 'row_details', :locals=>{:p=>p}
    end
  end

  def display_retur_histories(rp_number)
    str = ''
    rps = ReturnedProcess.order("created_at asc").where("rp_number like ?", "%#{rp_number}%")

    has_dispute = false
    has_reject = false
    has_accept = false

    rps.each_with_index do |retur, i|
      state = retur.state_name.to_s
      text = state
      link = false

      case state
      when "received"
        text = "new"
      when "unread"
        text = "new"
      when "read"
        text = "new"
      when "disputed"
        has_dispute = true
        link = true
      when "rev"
        has_reject = true
        link = true

        count = retur.revision_to
        unless count.nil?
          text = "Revision##{count}"
        end
      when "accepted"
        str += "<span class='btn btn-minier history-btn disabled'>dispute</span>" if !has_dispute
        str += "<span class='btn btn-minier history-btn disabled'>revision</span>" if !has_reject
        has_dispute = true
        has_reject = true
        has_accept = true
        link = true
      end

      label = retur == rps.last ? "primary" : "default"
      row = i < rps.count - 5 ? "?row=#{rps.count - i}" : ""

      str += link ? (link_to text, get_retur_history_returned_processes_path(rps.last.id) + "#{row}#retur_#{retur.id}", :class => "btn btn-minier btn-#{label} history-btn")
                  : (button_tag text, :class => "btn btn-minier btn-#{label} history-btn", :disabled => "disabled")
    end

    str += "<span class='btn btn-minier history-btn disabled'>dispute</span>" if !has_dispute
    str += "<span class='btn btn-minier history-btn disabled'>revision</span>" if !has_reject
    str += "<span class='btn btn-minier history-btn disabled'>accepted</span>" if !has_accept

    "<div class='histories-div'>" + str + "</div>"
  end

  def check_dispute_history(rp)
    check_disp = ReturnedProcess.where("state in (3,4) AND rp_number = '#{rp.rp_number}'").count
    if check_disp == 0
      return true
    end
  end

  def retur_dispute_flow_selector(po)
    ReturnedProcess
        .where("rp_number = ? AND user_level = ? AND state = 4", po.rp_number, po.user_level)
  end
end
