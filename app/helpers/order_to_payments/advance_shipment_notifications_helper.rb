module OrderToPayments::AdvanceShipmentNotificationsHelper
  def check_path_for_asn(asn)
  	return order_to_payments_create_asn_path if asn.id.nil?
  	return order_to_payments_create_asn_path(asn.id) if !asn.id.nil?
  end

  def asn_to_unread(po)
  	if po.order_type == "#{ASN}"
      if po.asn_unread?
        po.to_read_asn if po.can_to_read_asn?
      end
    end
    state_label_for(po)
  end
end
