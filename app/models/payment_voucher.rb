class PaymentVoucher < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :warehouse
  has_many :payment_voucher_details
  has_one :payment_element
  belongs_to :user
  accepts_nested_attributes_for :payment_voucher_details, :allow_destroy => true, :reject_if => proc { |obj| obj.blank? }
  attr_accessible :payment_voucher_details_attributes, :voucher, :approved_from, :grand_total, :is_history, :is_approved
  attr_protected :supplier_id, :user_id
  before_save :generate_voucher
  after_save :save_activity
  has_many :user_logs, :as => :log
  include ApplicationHelper
  include ActionView::Helpers::NumberHelper

  paginates_per PER_PAGE
  state_machine :is_approved, :initial => :new do
    state :new, :value => 0
    state :pending, :value => 1
    state :approved, :value => 2

    event :approve_1 do
      transition :new => :pending
    end
    event :approve_2 do
      transition :pending => :approved
    end

    after_transition :on => :approve_1, :do => :save_activity
    after_transition :on => :approve_2, :do => :save_activity
  end

  state_machine :payment_state, :initial => :unused, :namespace=> "payment" do
    state :unused, :value => 0
    state :used, :value => 1
    state :paid_off, :value => 2

    event :use do
      transition :unused => :used
    end
    event :unuse do
       transition :used => :unused
    end
    event :pay_off do
      transition :used => :paid_off
    end

    after_transition :on => :use, :do => :save_activity
    after_transition :on => :unuse, :do => :save_activity
    after_transition :on => :pay_off, :do => :save_activity
  end

  def save_activity
    ul = UserLog.new(:log_type => self.class.model_name, :event => self.payment_state_name.to_s, :transaction_type => "#{PV}" )
    ul.user_id = self.user_id
    ul.log_id = self.id
    ul.save
  end

  def export_to_xls
    book = Spreadsheet::Workbook.new
    column_bold = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :silver })
    details_column = Spreadsheet::Format.new({:pattern => 1, :pattern_fg_color => :yellow })
    disputed_grn_grpc = Spreadsheet::Format.new({:pattern => 1, :pattern_fg_color => :xls_color_38 })
    other_column = Spreadsheet::Format.new({:weight => :bold, :color => :white, :pattern => 1, :pattern_fg_color => :black })
    curr_format = Spreadsheet::Format.new({:weight => :bold, :pattern => 1, :pattern_fg_color => :xls_color_38, :number_format => 'Rp #,##0.00' })
    curr_format_yellow = Spreadsheet::Format.new({:weight => :bold, :pattern => 1, :pattern_fg_color => :yellow, :number_format => 'Rp #,##0.00' })
    cur_total_format = Spreadsheet::Format.new({:weight => :bold, :pattern => 1, :color => :white, :pattern_fg_color => :black, :number_format => 'Rp #,##0.00' })
    middle_template = ["Supplier Code", "Order Date", "Received Date", "Payment Invoice Due Date", "Invoice Number", "Grand Total"]

    left_header_template = ["Voucher", 'Last Update By']
    sheet1 = book.create_worksheet :name => "Payment Voucher"
    self_order = payment_voucher_details

#========================== HEADER ====================================
    2.times do |t|
      # ============  LEFT HEADER
      #column 0
      sheet1.row(t).default_format = column_bold
      sheet1[t, 0] = left_header_template[t]
    end

    # ============= VALUE LEFT HEADER
    sheet1[0, 2] = self.voucher
    sheet1[1, 2] = "#{user.first_name} #{user.last_name}"
#======================= END HEADER ===================================
    ["Supplier Code", "Order Date", "Received Date", "Payment Invoice Due Date", "Invoice Number", "Grand Total"].each_with_index{|lh, i|
      sheet1[4, i] = lh
    }

#======================= MIDDLE DETAIL TRANSACTION ===========================
    number = 0
    index = 0

    self_order.each_with_index do |detail,i|
      i += 5
      index = i
      number += 1
      sheet1[i, 0] = detail.purchase_order.supplier.code
      sheet1[i, 1] = convert_date(detail.purchase_order.po_date)
      sheet1[i, 2] = convert_date(detail.purchase_order.received_date)
      sheet1[i, 3] = convert_date(detail.purchase_order.payment_invoice_due_date)
      sheet1[i, 4] = detail.purchase_order.invoice_number
      sheet1[i, 5] = total_format(detail.purchase_order.charges_total, "Rp.")
    end
  #======================================================================
    path = "#{Rails.root}/public/purchase_order_xls/grn_excel-file.xls"

    book.write path
    return path
  end

  #Auth: Leonardo
  #desc : generate payment voucher
  def generate_voucher
    if self.voucher.blank?
      supplier_code = supplier.code
      datetime = Time.now.to_f
      self.voucher = "#{supplier_code}#{datetime.to_s.split(".").join()}"
    end
  end

  def self.save_payment_voucher(options, wh_id, user)
    supplier = Supplier.find_by_name(options["supplier_name_autocomplete"])
    begin
      ActiveRecord::Base::transaction do
        if options["select"].present?
          payment_voucher = PaymentVoucher.new
          payment_voucher.supplier_id = supplier.id
          payment_voucher.warehouse_id = wh_id
          payment_voucher.user_id = user.id
          payment_voucher.payment_state = user.roles.first.features.where(:name => 'Approval from customer', :regulator => 'PaymentVoucher').first.nil? ? 0 : 1
          #if payment_voucher.valid?
          total_ammount = 0;
          options["select"].collect{|k,v|
            detail = payment_voucher.payment_voucher_details.build
            detail.purchase_order_id = k
            total_ammount += detail.purchase_order.charges_total
          }
          payment_voucher.grand_total = total_ammount
            if payment_voucher.save
              payment_voucher.approve_invoice_selected(user) if user.roles.first.features.where(:name => 'Approval from supplier', :regulator => 'PaymentVoucher').present?
              PurchaseOrder.send_notifications(payment_voucher)
              payment_voucher.update_completed_payment_voucher_at_purchase_order
            end
          #end

          return payment_voucher
        end
      end
    rescue => e
      ActiveRecord::Rollback
    end

    return false
  end

  def self.filter_payment_voucher(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'voucher'
          where("payment_vouchers.voucher ilike ?", "%#{options[:search][:detail]}%")
        when 'supplier code'
          joins(:supplier).where("suppliers.code ilike ?", "%#{options[:search][:detail]}%")
        end
      else
         where("payment_vouchers.voucher ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      scoped
    end
  end

  def approve_invoice_selected(user)
    unless self.approved?
      payment_voucher = PaymentVoucher.new
      payment_voucher.voucher = self.voucher
      payment_voucher.supplier_id = self.supplier_id
      payment_voucher.is_approved = self.is_approved
      payment_voucher.grand_total = self.grand_total
      payment_voucher.warehouse_id = self.warehouse_id
      payment_voucher.user_id = user.id
      if payment_voucher.valid?
        self.payment_voucher_details.each do |det|
          pv_detail = self.payment_voucher_details.find(det.id)
          if pv_detail.present?
            detail = payment_voucher.payment_voucher_details.build
            detail.purchase_order_id = pv_detail.purchase_order_id
          end
        end
        payment_voucher.from_approved = user.roles.first.name
        state = self.is_approved_name.to_s
        case state.downcase
        when "new"
          #approval menjadi pending hanya dilakukan oleh customer
          if user.type_of_user.parent.customer? || user.has_role?("superadmin")
            payment_voucher.approve_1 if self.can_approve_1?
            # pv menjadi approved jika diatur pada role
            supp_role = User.where("supplier_id=#{payment_voucher.supplier_id}").map{|a|a.roles.first}.uniq
            need_approval = false
            supp_role.each{|r|
              if r.features.where(:name => 'Approve invoice', :regulator => 'PaymentVoucher').present?
                need_approval = true
                break
              end
            }
            unless need_approval
              payment_voucher.approve_2
            end
            PurchaseOrder.send_notifications(payment_voucher)
          else
            return false
          end
        when "pending"
          #approval menjadi pending hanya dilakukan oleh supplier
          if user.type_of_user.parent.supplier? || user.has_role?("superadmin")
            payment_voucher.approve_2 if self.can_approve_2?
            PurchaseOrder.send_notifications(payment_voucher)
          end
        end
        self.update_attributes(:is_history => true)
      end
    end
  end

  #Author : Leonardo
  #desc : Update PO untuk payment voucher yang sudah di generate
  def update_completed_payment_voucher_at_purchase_order
    details = self.payment_voucher_details
    details.each do |detail|
      detail.purchase_order.update_attributes(:is_payment_voucher_completed => true)
    end
  end
end
