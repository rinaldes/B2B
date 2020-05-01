class PaymentVoucherDetail < ActiveRecord::Base
  attr_protected :payment_voucher_id, :purchase_order_id
  belongs_to :payment_voucher
  belongs_to :purchase_order

  def self.filter(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'supplier code'
          joins(:purchase_order => [:supplier]).where("suppliers.code ilike ?", "%#{options[:search][:detail]}%")
        when 'po number'
          joins(:purchase_order).where("purchase_orders.po_number ilike ?", "%#{options[:search][:detail]}%")
        when 'grn number'
          joins(:purchase_order).where("purchase_orders.grn_number ilike ?", "%#{options[:search][:detail]}%")
        when 'invoice_number'
          joins(:purchase_order).where("purchase_orders.invoice_number ilike ?", "%#{options[:search][:detail]}%")
        end
      end
    else
      scoped
    end
  end
end
