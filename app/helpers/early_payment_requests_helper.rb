module EarlyPaymentRequestsHelper
  def show_link_take_action(pr)
    str = ""
    if pr.can_sending? && can?(:send_payment_request, pr)
      path = send_payment_request_early_payment_request_url(pr.id)
      str = "<li>"
      str += (link_to "<i class='icon-share'> </i> Send".html_safe, 'javascript:void(0)', :onclick => "confirmPaymentRequest('#{path}','Send')")
      str += "</li>"
    elsif (pr.can_accept? || pr.can_reject?)
      if can?(:accept_payment_request, pr)
        str = "<li>"
        str += (link_to "<i class='icon-ok'> </i> Accept".html_safe, 'javascript:void(0)', :onclick => "confirmPaymentRequest('#{new_detail_bank_early_payment_request_path(pr.id)}','Accept')")
        str += "</li>"
      end
      if  can?(:reject_payment_request, pr)
        path = reject_payment_request_early_payment_request_url(pr.id)
        str += "<li>"
        str += (link_to "<i class='icon-remove'> </i> Reject".html_safe, 'javascript:void(0)', :onclick => "confirmPaymentRequest('#{path}','Reject')")
        str += "</li>"
      end
    end
    return str.html_safe
  end

  def grand_total(total)
    gatot = 0
    total.collect{|total|
      gatot += total
    }

    return gatot
  end
end
