GeneralSetting.delete_all
GeneralSetting.create(:desc => "Background Color", :value => "ffffff")
GeneralSetting.create(:desc => "Login Title", :value => "Selamat Datang :)")
GeneralSetting.create(:desc => "Last GRN Approval", :value => "Supplier", :input_type => "dropdown", :value2 => "Supplier;Customer")
GeneralSetting.create(:desc => "Last GRPC Approval", :value => "Supplier", :input_type => "dropdown", :value2 => "Supplier;Customer")
GeneralSetting.create(:desc => "Last DN Approval", :value => "Supplier", :input_type => "dropdown", :value2 => "Supplier;Customer")
GeneralSetting.create(:desc => "Last RP Approval", :value => "Supplier", :input_type => "dropdown", :value2 => "Supplier;Customer")
Feature.create(:name => "Approval from supplier", :description => "", :key => "Payments/need_approval", :regulator => "Payment")
Feature.create(:name => "Approval from customer", :description => "", :key => "PaymentVouchers/need_approval", :regulator => "PaymentVoucher")
Feature.new(:name => "Approval from supplier", :description => "", :key => "PaymentVouchers/need_approval", :regulator => "PaymentVoucher")
Feature.create(:name => "Edit asn", :description => "", :key => "OrderToPayments::AdvanceShipmentNotifications/edit", :regulator => "AdvanceShipmentNotification")
Feature.create(:name => "Cancel asn", :description => "", :key => "OrderToPayments::AdvanceShipmentNotifications/destroy", :regulator => "AdvanceShipmentNotification")
SupplierLevelDetail.create text: 'Service Level Supplier'
SupplierLevelDetail.create text: "On Going Disputes"
SupplierLevelDetail.create text: "Pending Deliveries"
SupplierLevelDetail.create text: "Return Histories"
SupplierLevelDetail.create text: "Account Payable"
SupplierLevelDetail.create text: "Account Receivable"
SupplierLevelDetail.create text: "Payment Progress"