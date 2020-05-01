class Payment < ActiveRecord::Base
  belongs_to :user
  belongs_to :warehouse
  belongs_to :supplier
  belongs_to :purchase_order, foreign_key: 'invoice_id'

  has_many :payment_details

  accepts_nested_attributes_for :payment_details, allow_destroy: true, reject_if: proc { |obj| obj.blank? }
  attr_accessor :error_temp
  attr_accessible :payment_details_attributes, :error_temp, :invoice_id

  state_machine initial: :pending do
    state :pending, value: 0
    state :approved, :value => 1
    state :rejected, :value => 2
    state :paid, value: 3

    event :approve do
      transition :pending => :approved
    end
    event :reject do
      transition :pending => :rejected
    end
    event :pay do
      transition :approved => :paid
    end
  end

  def self.filter(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'payment no'
          res = joins(:supplier, :warehouse).where("payments.no ilike ?", "%#{options[:search][:detail]}%")
        when 'supplier code'
          res = joins(:supplier,:warehouse).where("suppliers.code ilike ?", "%#{options[:search][  :detail]}%")
        when 'warehouse code'
          res = joins(:warehouse,:supplier).where("warehouses.warehouse_code ilike ?", "%#{options[:search][:detail]}%")
        when 'status'
          status = options[:search][:detail].split(" ").join("_")
          begin
            res = joins(:warehouse, :supplier).with_state(status.to_sym)
            rescue => e
            return res = where(:state=>nil) #return empty array active record if state does not included valid state
          end
        else
          res = joins(:supplier, :warehouse).where("no ilike ?", "%#{options[:search][:detail]}%")
        end
      else
        res = joins(:supplier, :warehouse).where("no ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      res = scoped
    end
    return res
  end

  def self.create_payment(current_ability, params, user)
    payment = Payment.new(params[:payment].merge(invoice_id: (PurchaseOrder.find_by_invoice_number(params[:invoice_number]).id rescue nil)))
    payment.user_id = user.id
    if user.roles.first.features.where(:name => 'Approval from supplier', :regulator => 'Payment').present?
      payment.state = 0
    else
      payment.state = 1
    end

    #check params as detail payment one by one
    #begin
      ActiveRecord::Base.transaction do
         payment = save_a_payment(payment,current_ability)
         if payment.errors.any?
           return payment
         else
            if payment.save && payment.payment_element_to_used
              PurchaseOrder.send_notifications(payment)
              return payment
            else
               ActiveRecord::Rollback
               payment.errors.add(:error_temp, "An error has ocurred when saving payment, please forgive us for this inconvenience")
               return payment
            end
         end
      end
      return payment
    #rescue => e
     #  ActiveRecord::Rollback
      # return payment
    #end
  end

  def self.save_a_payment(payment,current_ability)
    supplier = ''
    warehouse = ''
    supp_id = 0
    wh_id = 0
    pv_flag = false
      if payment.valid?
        payment.payment_details.each_with_index do |pd, i|
          case pd.temp_type
            when "PaymentVoucher"
              pd_of = PaymentVoucher.with_payment_state(:unused).accessible_by(current_ability).where(:id=>pd.temp_detail_candidate).first
              pd.total = pd.temp_total
              supp_id = pd_of.supplier_id
              wh_id = pd_of.warehouse_id
            when "DebitNote"
              pd_of = DebitNote.with_payment_state(:unused).accessible_by(current_ability).where(:id=>pd.temp_detail_candidate).first
              pv_flag = true
              pd.total = pd.temp_total
              supp_id = pd_of.supplier_id
              wh_id = pd_of.warehouse_id
            when "ReturnedProcess"
              pd_of = ReturnedProcess.with_payment_state(:unused).accessible_by(current_ability).where(:id=>pd.temp_detail_candidate).first
              pv_flag = true
              pd.total = pd.temp_total
              supp_id = pd_of.purchase_order.supplier_id
              wh_id = pd_of.purchase_order.warehouse_id
          end
          if pd_of.blank?
            payment.errors.add(:error_temp, "Record(s) not found, or you're trying to get record that doesn't belong to you 1")
            return payment
          end
          if supplier.blank?
            supplier = supp_id
          else
            if supplier != supp_id
              payment.errors.add(:error_id, "Record(s) not found, or you're trying to get record that doesn't belong to you 2")
              return payment
            end
          end
          if warehouse.blank?
             warehouse = wh_id
          else
            if warehouse != wh_id && Warehouse.find_by_id(warehouse).group_id != Warehouse.find_by_id(wh_id).group_id
             raise "#{i}: #{wh_id}, #{warehouse}, #{pd.temp_type}".inspect
              payment.errors.add(:error_temp, "Record(s) not found, or you're trying to get record that doesn't belong to you 3aaa")
              return payment
            end
          end
          pd.payment_element_id = pd_of.id
          pd.payment_element_type = pd_of.class.name
          payment.total = 0 if payment.total.nil?
          payment.total += pd.total if pd.payment_element_type == "PaymentVoucher"
          payment.total -= pd.total if pd.payment_element_type == "DebitNote" || pd.payment_element_type == "ReturnedProcess"
        end
        #payment.errors.add(:error_temp, "You must select at least one debit note or returned process first!") unless pv_flag
        payment.supplier_id = supplier
        payment.warehouse_id = warehouse
        payment.generate_payment_no
        return payment
      end
  end

  def generate_payment_no
    if self.no.blank?
      supplier_code = self.supplier.code
      datetime = Time.now.to_f
      self.no = "#{supplier_code}#{datetime.to_s.split(".").join()}"
    end
  end

  def payment_element_to_used
    self.payment_details.each do |pd|
      unless pd.payment_element.use_payment
        return false
      end
    end
    return true
  end

  def payment_element_to_paid_off
    self.payment_details.each do |pd|
      unless (pd.payment_element.pay_off_payment rescue true)
        return false
      end
    end
    return true
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

    left_header_template = ["Payment No", 'From', 'To', 'Status', 'Last Update By']
    sheet1 = book.create_worksheet :name => "Payment Voucher"

#========================== HEADER ====================================
    5.times do |t|
      # ============  LEFT HEADER
      #column 0
      sheet1.row(t).default_format = column_bold
      sheet1[t, 0] = left_header_template[t]
    end

    # ============= VALUE LEFT HEADER
    sheet1[0, 2] = self.no
    sheet1[1, 2] = self.warehouse.warehouse_name
    sheet1[2, 2] = supplier.name
    sheet1[3, 2] = state_name.to_s
    sheet1[4, 2] = "#{user.first_name} #{user.last_name}"
#======================= END HEADER ===================================

#======================= Voucher(s) ===========================
    sheet1[7, 0] = "Voucher(s)"
    sheet1[8, 0] = "No"
    sheet1[8, 1] = "Detail Reference No"
    sheet1[8, 2] = "Total"
    if payment_details.where(payment_element_type: "PaymentVoucher").present?
      payment_details.where(payment_element_type: "PaymentVoucher").each_with_index do |pd,i|
        
      end
    else
      sheet1[8, 1] = "No Voucher was/were used"
    end



    number = 0
    index = 0

    path = "#{Rails.root}/public/purchase_order_xls/grn_excel-file.xls"

    book.write path
    return path
  end

  def payment_element_to_unused
    self.payment_details.each do |pd|
      unless pd.payment_element.unuse_payment
        return false
      end
    end
    return true
  end

  def self.reject_payment(payment, user)
    begin
      ActiveRecord::Base.transaction(requires_new: true) do
        if payment.can_reject? && payment.payment_element_to_unused
          payment.reject
          payment.user_id = user.id
          payment.save
          PurchaseOrder.send_notifications(payment)
        else
          payment.errors.add(:error_temp, "something wrong happen, or you're trying to reject payment that doesn't belong to you ")
          ActiveRecord::Rollback
          return payment
        end
      end
      return payment
    end
    rescue => e
      ActiveRecord::Rollback
      payment.errors.add(:error_temp, "an error has ocurred when rejecting payment, forgive us for this inconvenience")
      return payment
  end

  def self.accept_payment(payment, user)

    begin
      ActiveRecord::Base.transaction(requires_new: true) do
        if payment.can_approve? && payment.payment_element_to_paid_off
          payment.approve
          payment.user_id = user.id
          payment.payment_date = Time.now
          payment.save
          OffsetApi.push_data("b2bpayment", payment.prep_json)
          PurchaseOrder.send_notifications(payment)
        else
          payment.errors.add(:error_temp, "something wrong happen, or you're trying to approve payment that doesn't belong to you ")
          ActiveRecord::Rollback
          return payment
        end
      end
      return payment
    end
    rescue => e
      ActiveRecord::Rollback
      payment.errors.add(:error_temp, "an error has ocurred when rejecting payment, forgive us for this inconvenience")
      return payment
  end

  def prep_json
    val = []
    val << "'b2b_supplier_id': '#{supplier.code rescue ''}'"
    val << "'b2b_warehouse_id': '#{warehouse.warehouse_code rescue ''}'"
    val << "'b2b_total_payment': #{total}"
    val << "'b2b_state': '#{state_name.to_s}'"
    val << "'b2b_created_at': '#{created_at}'"
    val << "'b2b_updated_at': '#{updated_at}'"
    val << "'b2b_no': '#{no}'"
#    val << "\"b2b_payment_date\": \"#{payment_date.strftime('%Y-%m-%d %H:%M:%S 0')}\""
    val << "'b2b_user_id': '#{user.username rescue ''}'"

    return "{#{val.join(",").gsub!("'", '"')}}"
  end

end
