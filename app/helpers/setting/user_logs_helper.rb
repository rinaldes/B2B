module Setting::UserLogsHelper
  def get_selected_history
    str = ""
    if can?(:login_history, :user_log)
      str = "<option value='0'>History Login Activity</option>"
    end

    if can?(:transaction_history, :user_log)
      if str.blank?
        str = "<option value='1'>History Transaction Activity</option>"
      else
        str += "<option value='1'>History Transaction Activity</option>"
      end
    end
    select_tag "history_log_selected", str.html_safe, :onchange => "get_history(this.value)"
  end

  def is_only_po_payment_epr_pv?(act)
    act.log_type == "PurchaseOrder" || act.log_type == "Payment" || act.log_type == "EarlyPaymentRequest" || act.log_type == "PaymentVoucher"
  end
end
