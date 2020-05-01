module OrderToPayments::PurchaseOrdersHelper
  def total_po(total)
    gatot = 0
    total.collect {|t|
      gatot = gatot + t.to_f
    }
    gatot
  end

  def dispute_escalated(po, type)
    po.update_attribute(:user_level, po.user_level + 1)

    case type
    when GRN
      transaction_type = "GRN"
    when GRPC
      transaction_type = "GRPC"
    when DN
      transaction_type = "Debit Note"
    when RP
      transaction_type = "Return Process"
    end

    # send email
    case type
    when DN
      users = DebitNote.joins("left join users on users.id = debit_notes.user_id")
                       .where("order_number = '#{po.order_number}' and user_id is not null")
                       .group(:email).pluck(:email)
      UserMailer.mailer_dispute(po.order_number, users, transaction_type).deliver rescue ''
    when RP
      users = ReturnedProcess.joins("left join users on users.id = returned_process.user_id")
                       .where("rp_number = '#{po.rp_number}' and user_id is not null")
                       .group(:email).pluck(:email)
      UserMailer.mailer_dispute(po.rp_number, users, transaction_type).deliver rescue ''
    else
      users = PurchaseOrder.joins("left join users on users.id = purchase_orders.user_id")
                           .where("order_type='#{type}' and po_number='#{po.po_number}' and user_id is not null")
                           .group(:email).pluck(:email)
      UserMailer.mailer_dispute(po.po_number, users, transaction_type).deliver rescue ''
    end
  end

  def dispute_escalated?(po, type, selector)
    case type
    when GRN
      transaction_type = "GRN"
      return false if po.grn_state != 3 && po.grn_state != 4
    when GRPC
      transaction_type = "GRPC"
      return false if po.grpc_state != 3 && po.grpc_state != 4
    when DN
      transaction_type = "Debit Note"
      return false if po.state != 1 && po.state != 2
    when RP
      transaction_type = "Return Process"
      return false if po.state != 4 && po.state != 5
    end

    setting = UserLevelDispute.where("user_id = ? and transaction_type='#{transaction_type}'", current_user.id).joins(:dispute_setting).first

    # jika tidak ada settingan maka eskalasi tidak terjadi
    return false if setting.nil?

    # user level di bawah level yang diperbolehkan untuk approve
    return true if po.user_level > setting.level

    # dispute/revisi melebihi batas putaran yang diperbolehkan
    # (asumsi setiap putaran punya 2 record).
    # 1 putaran = dispute -> rejected
    # 2 putaran = dispute -> rejected -> dispute -> rejected
    # selector digunakan untuk mengambil record yg disputed
    if method(selector).call(po).count() >= setting.dispute_setting.max_round
      dispute_escalated(po, type)
      return dispute_escalated?(po, type, selector)
    end

    time = 1.hour # default set ke jam
    if setting.dispute_setting.time_type == "Day"
      time = 1.day
    end

    # Jika update terakhir melebihi waktu eskalasi, maka tingkatkan
    # level user yang bisa mengapprove sebanyak 1 tingkat
    if ((Time.now - po.updated_at) / time).round >= setting.dispute_setting.max_count
      dispute_escalated(po, type)
      return dispute_escalated?(po, type, selector)
    end

    return false
  end
end
