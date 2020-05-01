module PaymentVouchersHelper
  def show_button_approved_invoice_by_empo(pv, f)
    arr = []
    unless pv.approved?
      if can?(:approve_invoice, pv)
        if pv.new?
          arr << "<div class='controls pull-right'>"
          arr << (f.button raw('Approve Selected Invoice<i class="icon-arrow-right icon-on-right"></i>'), :class => "btn btn-small btn-success btn-register-span5", :data => { :confirm => "Approve selected Invoice?" })
          arr << "</div>"
        end
      end
    end
    return arr.join("").html_safe
  end

  def show_button_approved_invoice_by_supplier(pv, f)
    arr = []
    unless pv.approved?
      if can?(:approve_invoice, pv)
        if pv.pending?
          arr << "<div class='controls pull-right'>"
          arr << (f.button raw('Approve Selected Invoice<i class="icon-arrow-right icon-on-right"></i>'), :class => "btn btn-small btn-success btn-register-span5", :data => { :confirm => "Approve selected Invoice?" })
          arr << "</div>"
        end
      end
    end
    return arr.join("").html_safe
  end

  def show_button_print_invoice(pv)
    path = ""
    if pv.approved? && can?(:print_from_supplier, pv)
      path = get_print_from_supplier_path(params[:id])
    else
      path = get_print_from_empo_path(params[:id])
    end

    arr = []
      arr << "<div class='controls pull-right'>"
      arr << (link_to raw('Print Invoice<i class="icon-print icon-on-right"></i>'), path, :class => "btn btn-info btn-small", :target => "_blank", :data => { :confirm => "Print selected Invoice?" })
      arr << "</div>"
    return arr.join("").html_safe
  end
end
