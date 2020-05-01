module PaymentsHelper
	def total_payment_detail(details)
	   total = 0
	   unless details.blank?
		   details.each do |pd|
		     total += pd.total
		   end
	   end
	   return total
	end
	def display_details_per_type(details, title)
		render :partial => "payments/display_details_per_type", :locals=>{:details=>details, :title=>title}
	end
	def display_element_payment_no(pd)
		case pd.payment_element.class.name
		when "PaymentVoucher"
			return pd.payment_element.voucher
		when "DebitNote"
			return "Debit Note No #{pd.payment_element.tracking_no}-#{pd.payment_element.batch}"
		when "ReturnedProcess"
			return "Return No #{pd.payment_element.rp_number}"
		end
	end
	def display_print_button(payment)
		str=''
		if payment.approved?
		  str = link_to "<i class='icon-print'></i>Print".html_safe, print_payment_path(payment.id), :class=> "btn btn-info", :target => "_blank"
		end
		return raw(str)
	end
end
