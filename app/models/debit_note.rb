class DebitNote < ActiveRecord::Base
  attr_accessor :from_action
  attr_accessible :grand_total, :order_number, :transaction_date, :suffix, :type, :invoice_date,
                  :reference, :details, :due_date, :tracking_type, :tracking_no,
                  :batch, :dn_remark, :from_action, :is_history, :financial_period,
                  :financial_year, :branch_number, :updated_date, :updated_time, :amount
  attr_protected :supplier_id, :warehouse_id, :state, :user_id
  belongs_to :warehouse
  belongs_to :supplier
  belongs_to :user

  has_many :user_logs, :as => :log
  has_many :debit_note_lines
  accepts_nested_attributes_for :debit_note_lines

  belongs_to :parent, :class_name => "DebitNote"
  has_many :debit_notes, :foreign_key => "parent_id"
  scope :only_type_in, proc { where(:trans_type => 'IN') }
  scope :only_type_cr, proc { where(:trans_type => 'CR') }
  include ApplicationHelper

  paginates_per PER_PAGE
  StateMachine::Machine.ignore_method_conflicts = true

  # state_machine :dn_state, :initial => :nil, :namespace => 'dn' do
  #   after_transition :on => :raise_dispute, :do => :save_activity
  #   after_transition :on => :resolve, :do => :save_activity
  #   after_transition :on => :accept, :do => :save_activity

  #   event :to_unread do
  #     transition :nil => :unread,:if => lambda {|po| po.order_type == "#{DN}"}
  #   end
  #   event :read do
  #     transition :unread => :read
  #   end
  #   event :raise_dispute do
  #    transition [:read, :rev] => :dispute, :if => lambda {|po| po.count_rev_of("#{DN}") <= 20 }
  #   end
  #   event :resolve do
  #     transition :dispute => :rev
  #   end
  #   event :accept do
  #     transition [:read, :rev, :dispute ] => :accepted
  #   end
  #   event :expire do
  #      transition [:read, :dispute, :rev] => :expired, :if => lambda {|po| po.due_date > Date.now }
  #   end
  #   state :nil, :value =>0
  #   state :unread, :value => 1
  #   state :read, :value => 2
  #   state :dispute, :value=>3
  #   state :rev, :value=> 4
  #   state :accepted, :value =>5
  #   state :expired, :value => 6

  # end

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


  state_machine :state, :initial => :pending do
    state :pending, :value => nil
    state :disputed, :value => 1
    state :revisioned, :value => 2
    state :accepted, :value => 3
    state :rejected, :value => 4
    state :expired, :value => 5
    state :waiting_approval, :value => 6

    event :dispute do
       transition :rejected => :disputed
    end

    event :accept do
      transition [:pending, :disputed, :revisioned, :waiting_approval] => :accepted
    end

    event :reject do
      transition [:pending, :disputed] => :rejected
    end

    event :expire do
      transition [:pending, :disputed, :revisioned] => :expired, :if => :is_expired?
    end
    after_transition :on => :dispute, :do => :save_activity
    after_transition :on => :accept, :do => :save_activity
    after_transition :on => :reject, :do => :save_activity
  end

  def can_be_revised? current_user
    if GeneralSetting.where(:desc => "Last DN Approval").first.value == "Customer"
      current_user.warehouse.present? && DebitNote.where("user_id=#{current_user.id} AND order_number='#{order_number}'").count < DisputeSetting.find_by_transaction_type('Debit Note').max_round-1
    else
      current_user.warehouse.present? && DebitNote.where("user_id=#{current_user.id} AND order_number='#{order_number}'").count < DisputeSetting.find_by_transaction_type('Debit Note').max_round
    end
  end

  def save_activity
    unless self.user_id.blank?
      ul = UserLog.new(:log_type => self.class.model_name, :event => self.state_name.to_s, :transaction_type => "#{DN}" )
      ul.user_id = self.user_id
      ul.log_id = self.id
      ul.save
    end
  end

  def self.is_period_blank(period)
    date = ''
    begin
      date = period.to_date
    rescue => e
      return date = ''
    end
    unless period.blank?
      date = period.to_date
    end
    return date
  end

  def total_amount
    DebitNote.where("reference='#{reference}' AND is_history IS FALSE").map(&:amount).sum
  end

  #this function is used to create revised grn from disputed one
  def self.create_revised_dn(prev_dn,params, user)
    last_key = 0
    arr_seq_existed = []
    revision_to = self.where(:order_number => "#{prev_dn.order_number}").with_state(:revisioned).count + 1
    disputed_dn = prev_dn
    params[:debit_note].merge!(disputed_dn.attributes.except("id", "updated_at", "created_at", "dn_remark", "is_history", "supplier_id", "warehouse_id", "user_id","state", "is_published", "is_completed"))

    params[:debit_note][:debit_note_lines_attributes].each do |k, v|
      det = disputed_dn.debit_note_lines.where(:sol_line_seq => v["sol_line_seq"].to_i).last
      params[:debit_note][:debit_note_lines_attributes][k].merge! det.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id","seq")
      arr_seq_existed << det.sol_line_seq
      last_key = k.to_i
    end

    undisputed = disputed_dn.debit_note_lines.where("sol_line_seq NOT IN (#{arr_seq_existed.join(',')})").order("sol_line_seq ASC")
    undisputed.each do |d|
      last_key += 1
      params[:debit_note][:debit_note_lines_attributes].merge!({"#{last_key}" => {"remark" => "#{d.remark}"}})
      params[:debit_note][:debit_note_lines_attributes][last_key.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id")
      arr_seq_existed << d.sol_line_seq
    end

    new_revised_dn = DebitNote.new(params[:debit_note])
    new_revised_dn.insert_protected_attr(disputed_dn, user, 2)
    new_revised_dn.insert_product_id_to_po_details(disputed_dn, arr_seq_existed)
    new_revised_dn.revision_to = revision_to
    disputed_dn.is_history= true
    begin
      ActiveRecord::Base.transaction do
        if new_revised_dn.save && disputed_dn.save
#          new_revised_dn.resolve_grn if new_revised_dn.can_resolve_grn?
        end
      end
      PurchaseOrder.send_notifications(new_revised_dn)
      return new_revised_dn
    rescue => e
      ActiveRecord::Rollback
    end

    return false
  end

  def self.create_disputed_dn(prev_dn,params,user)
    last_key = 0
    arr_seq_existed = []
    params[:debit_note].merge!(prev_dn.attributes.except("id", "updated_at", "created_at","dn_remark", "is_history", "supplier_id", "warehouse_id", "user_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed"))

    params[:debit_note][:debit_note_lines_attributes].each do |k, v|
      det = prev_dn.debit_note_lines.where(sol_line_seq: v["sol_line_seq"].to_i).last
      params[:debit_note][:debit_note_lines_attributes][k].merge! det.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id","dispute_qty", "seq")
      arr_seq_existed << det.sol_line_seq
      last_key = k.to_i
    end

    undisputed = prev_dn.debit_note_lines.where("sol_line_seq NOT IN (#{arr_seq_existed.join(',')})").order("sol_line_seq ASC")
    undisputed.each do |d|
      last_key += 1
      params[:debit_note][:debit_note_lines_attributes].merge!({"#{last_key}" => {"remark" => "#{d.remark}", "dispute_qty" => d.dispute_qty, "is_disputed" => false, "seq" => d.seq}})
      params[:debit_note][:debit_note_lines_attributes][last_key.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id","dispute_qty")
      arr_seq_existed << d.seq
    end

    new_dispute_dn = DebitNote.new(params[:debit_note])
    new_dispute_dn.insert_protected_attr(prev_dn,user, 1)
    new_dispute_dn.insert_product_id_to_po_details(prev_dn, arr_seq_existed)
    prev_dn.is_history = true
#    begin
      ActiveRecord::Base.transaction do
        if new_dispute_dn.save && prev_dn.save
          #new_dispute_dn.update_attributes(state: # if new_dispute_dn.can_raise_dispute_grn?
          PurchaseOrder.send_notifications(new_dispute_dn)
        end
      end
      return new_dispute_dn
 #   rescue => e
  #    ActiveRecord::Rollback
   # end

    return false
  end

  def insert_protected_attr(parent, user=nil, current_state)
     self.supplier_id = parent.supplier_id
     self.warehouse_id = parent.warehouse_id
     unless user.blank?
       self.user_id = user.id
     else
       self.user_id = parent.user_id
     end
     self.state = current_state
     self.is_published = parent.is_published
     self.is_history = parent.is_history
     self.is_completed = parent.is_completed
     self.updated_date = parent.updated_date
     self.updated_time = parent.updated_time
  end

  def insert_product_id_to_po_details(parent, seq=[])
    unless seq.blank?
      seq.each_with_index do |seq, i|
        det = parent.debit_note_lines.where(sol_line_seq: seq).last
        self.debit_note_lines[i].stock_code = det.stock_code
      end
    end
  end

  def self.check_between_two_date(period_1,period_2)
    date1 = DebitNote.is_period_blank(period_1)
    return false if date1.blank?
    date2 = DebitNote.is_period_blank(period_2)
    return false if date2.blank?
    return true if date1 == date2
  end

  def is_expired?
    false
    #self.due_date.to_date.strftime("%d/%m/%Y") > Date.today.strftime("%d/%m/%Y")
  end

  def remark_present?
    self.dn_remark.present?
  end

  def self.search_report(options, user=nil)
     unless options[:search].blank?
      status = options[:search][:detail].split(" ").join("_")
      if options[:search][:field].present?
        begin
          case options[:search][:field].downcase
            when "order number"
              res = where("debit_notes.order_number ilike ?", "%#{options[:search][:detail]}%")
            when "status"
              if options[:search][:detail] == "pending"
                res = only_type_in.where("debit_notes.state IS NULL")
              else
                res = only_type_in.with_state(status.to_sym)
              end
            end
        rescue => e
            res = where("order_number like ? AND state IS NULL", "%#{options[:search][:detail]}%")
        end

        #check transaction date
        if DebitNote.check_between_two_date(options[:search][:period_1],options[:search][:period_2])
          res = res.where("DATE(transaction_date) = ? ", DebitNote.is_period_blank(options[:search][:period_1])) unless DebitNote.is_period_blank(options[:search][:period_1]).blank?
        else
          res = res.where("DATE(transaction_date) >= ? ", DebitNote.is_period_blank(options[:search][:period_1])) unless DebitNote.is_period_blank(options[:search][:period_1]).blank?
          res = res.where("DATE(transaction_date) <= ? ", DebitNote.is_period_blank(options[:search][:period_2])) unless DebitNote.is_period_blank(options[:search][:period_2]).blank?
        end

        #check invoice date
        if DebitNote.check_between_two_date(options[:search][:period_1_inv_date],options[:search][:period_2_inv_date])
          res = res.where("DATE(invoice_date) = ? ", DebitNote.is_period_blank(options[:search][:period_1_inv_date])) unless DebitNote.is_period_blank(options[:search][:period_1_inv_date]).blank?
        else
          res = res.where("DATE(invoice_date) >= ? ", DebitNote.is_period_blank(options[:search][:period_1_inv_date])) unless DebitNote.is_period_blank(options[:search][:period_1_inv_date]).blank?
          res = res.where("DATE(invoice_date) <= ? ", DebitNote.is_period_blank(options[:search][:period_2_inv_date])) unless DebitNote.is_period_blank(options[:search][:period_2_inv_date]).blank?
        end

        #check due date
        if DebitNote.check_between_two_date(options[:search][:period_1_due_date],options[:search][:period_2_due_date])
          res = res.where("DATE(due_date) = ? ", DebitNote.is_period_blank(options[:search][:period_1_due_date])) unless DebitNote.is_period_blank(options[:search][:period_1_due_date]).blank?
        else
          res = res.where("DATE(due_date) >= ? ", DebitNote.is_period_blank(options[:search][:period_1_due_date])) unless DebitNote.is_period_blank(options[:search][:period_1_due_date]).blank?
          res = res.where("DATE(due_date) <= ? ", DebitNote.is_period_blank(options[:search][:period_2_due_date])) unless DebitNote.is_period_blank(options[:search][:period_2_due_date]).blank?
        end
      else
        res = scoped
      end
    else
      res = scoped
    end

    return res
  end

  def self.search(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'order number','asn number'
          res = where("po_number ilike ? ", "%#{options[:search][:detail]}%" )
        when 'grn number'
          res = where("grn_number ilike ?", "%#{options[:search][:detail]}%")
        when 'grpc number'
          res = where("grpc_number ilike ?", "%#{options[:search][:detail]}%")
        when 'invoice number'
          res = where("invoice_number ilike ? ", "%#{options[:search][:detail]}%" )
        when "status"
          status = options[:search][:detail].split(" ").map{ |s| s.to_sym }

          order_type = options[:controller].split("/")[1]
          begin
            res = with_states(*status)
            rescue => e
              return res = where(:state=>nil) #return empty array active record if state does not included valid state
          end
        end
        case order_type
        when "invoices", "debit_notes"
          period_date = "DATE(debit_notes.created_at)"
        else
          period_date = "DATE(po_date)"
        end
        if PurchaseOrder.check_between_two_date(options[:search][:period_1],options[:search][:period_2])
          res = res.where("#{period_date} = ? ", PurchaseOrder.is_period_blank(options[:search][:period_1])) unless PurchaseOrder.is_period_blank(options[:search][:period_1]).blank?
        else
          res = res.where("#{period_date} >= ? ", PurchaseOrder.is_period_blank(options[:search][:period_1])) unless PurchaseOrder.is_period_blank(options[:search][:period_1]).blank?
          res = res.where("#{period_date} <= ? ", PurchaseOrder.is_period_blank(options[:search][:period_2])) unless PurchaseOrder.is_period_blank(options[:search][:period_2]).blank?
        end
      else
        res = where("po_number ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      res = scoped
    end
    return res
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
    middle_template = ["No","Process","Date","Time","User","Remark"]

    left_header_template = ["Order Number","Warehouse Name","Supplier Name","Transaction Date","Invoice Date","Due Date","Status"]
    sheet1 = book.create_worksheet :name => "#{GRN}"
    self_order = DebitNote.where(:order_number => self.order_number).order("created_at ASC")
    #diambil data GRN yang last untuk accepted
    details_accepted = self_order.last.debit_note_lines.order("sol_line_seq ASC")
    details_title = ["Seq","Item Code","Barcode","Item Description","Commited QTY","Received QTY","Dispute QTY","UoM","Remark"]

#========================== HEADER ====================================
    9.times do |t|
      # ============  LEFT HEADER
      #column 0
      sheet1.row(t).default_format = column_bold
      sheet1[t, 0] = left_header_template[t]
    end

    # ============= VALUE LEFT HEADER
    sheet1[0, 2] = self.order_number
    sheet1[1, 2] = self.warehouse.warehouse_name
    sheet1[2, 2] = self.supplier.name rescue ''
    sheet1[3, 2] = convert_date(self.transaction_date)
    sheet1[4, 2] = convert_date(self.due_date)
    sheet1[5, 2] = convert_date(self.invoice_date)
    sheet1[6, 2] = self.state_name.to_s

    # ============= RIGHT HEADER
    sheet1[0, 4] = "Suffix"
    sheet1[1, 4] = "Tracking Type"
    sheet1[2, 4] = "Tracking Number"
    sheet1[3, 4] = "Reference"
    sheet1[4, 4] = "Batch"
    sheet1[5, 4] = "Amount"
    sheet1[6, 4] = "Last Update By"

    # ============= VALUE RIGHT HEADER
    sheet1[0, 6] = self.suffix
    sheet1[1, 6] = self.tracking_type
    sheet1[2, 6] = self.tracking_no
    sheet1[3, 6] = self.reference
    sheet1[4, 6] = self.batch
    sheet1[5, 6] = self.amount
    sheet1[6, 6] = "#{self.user.first_name} #{self.user.last_name}" rescue ""
#======================= END HEADER ===================================

#======================= MIDDLE DETAIL TRANSACTION ===========================
    6.times do |t|
      sheet1[10, t] = middle_template[t]
      sheet1.row(10).default_format = column_bold
    end

    number = 0
    index = 0

    self_order.each_with_index do |s,i|
      i += 11
      index = i
      number += 1
      sheet1[i, 0] = number
      sheet1[i, 2] = convert_date(s.created_at)
      sheet1[i, 3] = s.created_at.to_datetime.new_offset(Rational(7,24)).strftime("%H:%M:%S")
      sheet1[i, 4] = "#{s.user.first_name} #{s.user.last_name}" rescue ''
      sheet1[i, 5] = s.dn_remark
      sheet1.row(i).default_format = details_column
    end
  #======================================================================
    index += 2
    sheet1.row(index).default_format = other_column
    sheet1[index, 0] = "Debit Note Details"

  #===================== DETAIL TRANSACTION ACCEPTED ====================
    index += 1
    10.times do |d|
      sheet1[index, d] = details_title[d]
      sheet1.row(index).default_format = column_bold
    end

    index += 1
    index2 = index
    total_price, total_dispute_price = 0, 0
    details_accepted.each_with_index do |d,i|
      sheet1[index+i,0] = d.sol_line_seq
      sheet1[index+i,1] = d.product.code
      sheet1.column(1).width = 15
      sheet1[index+i,2] = d.product.apn_number
      sheet1.column(2).width = d.product.apn_number.to_s.length + 5
      sheet1[index+i,3] = d.product.name.gsub("<br/>","; ")
      sheet1[index+i,4] = d.sol_shipped_qty.to_i
      index2 += 1
    end
  #======================================================================
    path = "#{Rails.root}/public/purchase_order_xls/debit_note_excel-file.xls"

    book.write path
    return path
  end

  def last_update_by_other_user_current_by_current_user? current_user
    (user.roles.map(&:parent).include?(Role.find_by_name('customer')) && current_user.roles.map(&:parent).include?(Role.find_by_name('supplier')) || user.roles.map(&:parent).include?(Role.find_by_name('supplier')) && current_user.roles.map(&:parent).include?(Role.find_by_name('customer'))) rescue current_user.roles.map(&:parent).include?(Role.find_by_name('supplier'))
  end

  def self.filter_debit_notes(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'warehouse name'
          res = joins(:warehouse).where("warehouses.warehouse_name ilike ?", "%#{options[:search][:detail]}%")
        when 'supplier code'
          res = joins(:supplier).where("suppliers.code ilike ?", "%#{options[:search][:detail]}%")
        when 'tracking type'
          res = where("debit_notes.tracking_type ilike ?", "%#{options[:search][:detail]}%")
        when 'tracking number'
          res = where("debit_notes.tracking_number ilike ?", "%#{options[:search][:detail]}%")
        when "suffix"
          res = where("debit_notes.suffix ilike ?", "%#{options[:search][:detail]}%")
        when "order number"
          res = where("debit_notes.order_number ilike ?", "%#{options[:search][:detail]}%")
        when "reference"
          res = where("debit_notes.reference ilike ?", "%#{options[:search][:detail]}%")
        when "status"

          # == status pending punya nilai nil, bermasalah kalau pakai method with_states
          # status = options[:search][:detail].split(" ").map{ |s| s.to_sym }
          # res = with_states(*status)

          condition = []
          states = []
          options[:search][:detail].split(" ").each do |s|
            case s
            when "pending"
              condition << "state is null"
            when "disputed"
              states << "1"
            when "revisioned"
              states << "2"
            when "accepted"
              states << "3"
            when "rejected"
              states << "4"
            when "expired"
              states << "5"
            end
          end
          condition << "state in (#{states.join(",")})" if !states.empty?
          res = condition.empty?? where("1 = -1") : where(condition.join(" or "))
        end

        #check transaction date
        if DebitNote.check_between_two_date(options[:search][:period_1],options[:search][:period_2])
          res = res.where("DATE(transaction_date) = ? ", DebitNote.is_period_blank(options[:search][:period_1])) unless DebitNote.is_period_blank(options[:search][:period_1]).blank?
        else
          res = res.where("DATE(transaction_date) >= ? ", DebitNote.is_period_blank(options[:search][:period_1])) unless DebitNote.is_period_blank(options[:search][:period_1]).blank?
          res = res.where("DATE(transaction_date) <= ? ", DebitNote.is_period_blank(options[:search][:period_2])) unless DebitNote.is_period_blank(options[:search][:period_2]).blank?
        end

        #check invoice date
        if DebitNote.check_between_two_date(options[:search][:period_1_inv_date],options[:search][:period_2_inv_date])
          res = res.where("DATE(invoice_date) = ? ", DebitNote.is_period_blank(options[:search][:period_1_inv_date])) unless DebitNote.is_period_blank(options[:search][:period_1_inv_date]).blank?
        else
          res = res.where("DATE(invoice_date) >= ? ", DebitNote.is_period_blank(options[:search][:period_1_inv_date])) unless DebitNote.is_period_blank(options[:search][:period_1_inv_date]).blank?
          res = res.where("DATE(invoice_date) <= ? ", DebitNote.is_period_blank(options[:search][:period_2_inv_date])) unless DebitNote.is_period_blank(options[:search][:period_2_inv_date]).blank?
        end

        #check due date
        if DebitNote.check_between_two_date(options[:search][:period_1_due_date],options[:search][:period_2_due_date])
          res = res.where("DATE(due_date) = ? ", DebitNote.is_period_blank(options[:search][:period_1_due_date])) unless DebitNote.is_period_blank(options[:search][:period_1_due_date]).blank?
        else
          res = res.where("DATE(due_date) >= ? ", DebitNote.is_period_blank(options[:search][:period_1_due_date])) unless DebitNote.is_period_blank(options[:search][:period_1_due_date]).blank?
          res = res.where("DATE(due_date) <= ? ", DebitNote.is_period_blank(options[:search][:period_2_due_date])) unless DebitNote.is_period_blank(options[:search][:period_2_due_date]).blank?
        end
      else
        res = scoped
      end
    else
      res = scoped
    end
    return res
  end

  def self.save_debit_note_from_api(params, parent=nil)
    flag = false
    check_flag_all = []
    params['data'].each do |p|
      p['lines'] = OffsetApi.sync_debitnotelines(p['dr_tr_order_no'])['data']

      debit_note = DebitNote.where(:order_number => "#{p['dr_tr_order_no']}".squish).order("updated_at desc").first
      if !debit_note.blank? && debit_note.debit_note_lines.blank?
        p['lines'].each do |line|
          debit_note.debit_note_lines.build(
            :transaction_date => Time.at(line['sol_date_stamp'].to_i / 1000),
            :branch => p['br_acc_code'],
            :bo_suffix => line['so_bo_suffix'],
            :trans_type => line['sol_line_type'],
            :invoice => p['tr_invoice_date'],
            :ref => p['trans_ref'],
            :detail => p['tr_details'],
            :amount => line['sol_line_amount'],
            :batch => p['batch_ref'],
            :sol_line_seq => line['sol_line_seq'],
            :stock_code => line['stock_code'],
            :stk_unit_desc => line['stk_unit_desc'],
            :sol_tax_rate => line['sol_tax_rate'],
            :sol_item_price => line['sol_item_price'],
            :sol_shipped_qty => line['sol_shipped_qty'],
            :shipped_amount => line['shipped_amount']
          )
        end

        if !debit_note.save
       #   return flag = -1
        end
      end

      #check debit note dengan type IN ato CR
      if parent
        #jika debit note type CR
        debit_note = DebitNote.where(:batch => "#{p['batch_ref']}".squish).first

        if debit_note
#          next
        end

      # if debit_note.blank?
          debit_note = DebitNote.new(
            :order_number=> "#{p['dr_tr_order_no']}".squish,
            :transaction_date => "#{p['trans_date']}".squish,
            :suffix => "#{p['dr_tr_bo_suffix']}".squish,
            :trans_type => "#{p['trans_type']}".squish,
            :invoice_date => "#{p['tr_invoice_date']}".squish,
            :reference => "#{p['trans_ref']}".squish,
            :details => "#{p['tr_details']}".squish,
            :due_date => "#{p['dr_tr_due_date']}".squish,
            :tracking_type => "#{p['tr_document_type']}".squish,
            :tracking_no => "#{p['tr_document_no']}".squish,
            :batch => "#{p['batch_ref']}".squish,
            :financial_period => "#{p['financial_period']}",
            :financial_year => "#{p['financial_year']}",
            :branch_number => "#{p['br_acc_code']}",
            # :updated_date => p['dr_tr_date_stamp'].to_date.strftime('%Y-%m-%d'),
            :updated_date => p['dr_tr_time_stamp'].to_date.strftime('%H%M:%S')
          )

          p['lines'] = OffsetApi.sync_debitnotelines(p['dr_tr_order_no'])['data']
          p['lines'].each do |line|
            debit_note.debit_note_lines.build(
              :transaction_date => Time.at(line['sol_date_stamp'].to_i / 1000),
              :branch => p['br_acc_code'],
              :bo_suffix => line['so_bo_suffix'],
              :trans_type => line['sol_line_type'],
              :invoice => p['tr_invoice_date'],
              :ref => p['trans_ref'],
              :detail => p['tr_details'],
              :amount => line['sol_line_amount'],
              :batch => p['batch_ref'],
              :sol_line_seq => line['sol_line_seq'],
              :stock_code => line['stock_code'],
              :stk_unit_desc => line['stk_unit_desc'],
              :sol_tax_rate => line['sol_tax_rate'],
              :sol_item_price => line['sol_item_price'],
              :sol_shipped_qty => line['sol_shipped_qty'],
              :shipped_amount => line['shipped_amount']
            )
          end

          debit_note.amount = "#{p['tr_amount']}".to_f
          #simpan ID debit note yg type IN ke debit note yg type CR
          debit_note.parent_id = parent.id
          parent.amount = (parent.amount.to_f + debit_note.amount.to_f)

        #else
         # return flag = -1
        #end
      else
        #debit note type IN
        debit_note  = DebitNote.where(:reference => "#{p['trans_ref']}".squish).first
        #if debit_note.blank?
          debit_note = DebitNote.new(
            :order_number=> "#{p['dr_tr_order_no']}".squish,
            :transaction_date => "#{p['trans_date']}".squish,
            :suffix => "#{p['dr_tr_bo_suffix']}".squish,
            :trans_type => "#{p['trans_type']}".squish,
            :invoice_date => "#{p['tr_invoice_date']}".squish,
            :reference => "#{p['trans_ref']}".squish,
            :details => "#{p['tr_details']}".squish,
            :due_date => "#{p['dr_tr_due_date']}".squish,
            :tracking_type => "#{p['tr_document_type']}".squish,
            :tracking_no => "#{p['tr_document_no']}".squish,
            :batch => "#{p['batch_ref']}".squish,
            :financial_period => "#{p['financial_period']}",
            :financial_year => "#{p['financial_year']}",
            :branch_number => "#{p['br_acc_code']}",
            # :updated_date => p['dr_tr_date_stamp'].to_date.strftime('%Y-%m-%d'),
            :updated_date => p['dr_tr_time_stamp'].to_date.strftime('%H%M:%S')
          )

          p['lines'] = OffsetApi.sync_debitnotelines(p['dr_tr_order_no'])['data']
          p['lines'].each do |line|
            debit_note.debit_note_lines.build(
              :transaction_date => Time.at(line['sol_date_stamp'].to_i / 1000),
              :branch => p['br_acc_code'],
              :bo_suffix => line['so_bo_suffix'],
              :trans_type => line['sol_line_type'],
              :invoice => p['tr_invoice_date'],
              :ref => p['trans_ref'],
              :detail => p['tr_details'],
              :amount => line['sol_line_amount'],
              :batch => p['batch_ref'],
              :sol_line_seq => line['sol_line_seq'],
              :stock_code => line['stock_code'],
              :stk_unit_desc => line['stk_unit_desc'],
              :sol_tax_rate => line['sol_tax_rate'],
              :sol_item_price => line['sol_item_price'],
              :sol_shipped_qty => line['sol_shipped_qty'],
              :shipped_amount => line['shipped_amount']
            )
          end

          debit_note.amount = "#{p['tr_amount']}".squish.to_f
        #end
      end

      if debit_note.valid?
        #================== get data supplier ============================
        supplier = Supplier.get_data_supplier_by_code("#{p['accountcode']}".squish)
        if supplier
          debit_note.supplier_id = supplier.id
        else
          res = OffsetApi.connect_with_query("suppliers", "cre_accountcode", "#{p['accountcode']}".squish)

          next if  !res.is_a?(Net::HTTPSuccess)
          result = JSON.parse(res.body)
          next if result['data'].blank?
          save_supplier = Supplier.save_a_supplier_from_api(result)
          next if !save_supplier.instance_of?(Supplier)
          debit_note.supplier_id = save_supplier.id if save_supplier.present?
        end
        #===================================================================

        #================== get data warehouse ==============================
        warehouse = Warehouse.get_data_warehouse_by_code("#{p['dr_tr_whse_code']}".squish)
        if warehouse
          debit_note.warehouse_id = warehouse.id
        else
          res = OffsetApi.connect_without_offset_systbl("systable","#{p['dr_tr_whse_code']}".squish,"WH")
          next if !res.is_a?(Net::HTTPSuccess)
          result = JSON.parse(res.body)
          next if result['data'].blank?
          save_warehouse = Warehouse.save_a_warehouse_from_api(result)
          next if !save_warehouse.instance_of? Warehouse
          debit_note.warehouse_id = save_warehouse.id if save_warehouse.present?
        end
        #===================================================================

        if debit_note.save
          PurchaseOrder.send_email_notification_when_synch(debit_note)
          puts "save debit note #{debit_note.trans_type}"
          parent.save if parent.present?
        else
          return flag = false
        end
      end
    end
    return flag = true
  end

  def self.synch_debit_note_now
    #check offset
    flag =false
    offset = OffsetApi.where(:api_type=>"DebitNote")
    if offset.blank?
      offset_count = 0
      save_offset_type = OffsetApi.update_po_api_offset("DebitNote",offset_count)
    end
    offset = offset.last.offset
    begin
      res = OffsetApi.connect_with_offset_debit_note("debtrans",'trans_type', offset, API_LIMIT)
      rescue => e
      return flag = 2
    end

    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end

    result = JSON.parse(res.body)
    return flag = -1 if result['data'].blank?
    begin
      ActiveRecord::Base.transaction do
        save_debit_note = DebitNote.save_debit_note_from_api(result)
        return flag = save_debit_note if save_debit_note  != true
        if  OffsetApi.update_po_api_offset("DebitNote",result['count'])
           flag = true
        else
          return flag = false
        end
      return flag
      end
      rescue => e
      ActiveRecord::Rollback
        flag=false
        return flag
    end
    return flag
  end

  def self.synch_debit_note_periodically
    api = OffsetApi.where(:api_type=>"DebitNote").first
    unless api.blank?
      status = api.availability_status
      while status
        offset = api.offset
        begin
          res = OffsetApi.connect_with_offset_debit_note("debtrans", 'trans_type', offset, API_LIMIT)
          rescue => e
          OffsetApi.write_to_crontab_log(502,"DebitNote")
          break
        end
        unless res.is_a?(Net::HTTPSuccess)
           Offset.write_to_crontab_log(502,"DebitNote")
          break
        end
        result = JSON.parse(res.body)
        if result['data'].blank?
          OffsetApi.change_avalaible_status(api.api_type, false)
          OffsetApi.write_to_crontab_log(204,"DebitNote")
          status = false
        else
          begin
          ActiveRecord::Base.transaction do
            save_debit_note = DebitNote.save_debit_note_from_api(result, )
            if save_debit_note != true
              status = save_debit_note
            else
              OffsetApi.update_po_api_offset("DebitNote",result['count'])
            end
          end
          rescue => e
          ActiveRecord::Rollback
            status=false
             OffsetApi.write_to_crontab_log(500,"DebitNote")
            break
          end
        end
      end
    end
  end

  def synch_debit_note_details(user)
    begin
      res = OffsetApi.connect_with_query_debit_note("debtrans", "dr_tr_order_no","#{self.order_number}", "#{self.reference}")
    rescue => e
      return flag = 2
    end

    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)

    if result['data'].blank?
      return flag = -1
    else
      debit_note_action = DebitNote.save_debit_note_from_api(result, self)
      return flag = -1 if debit_note_action == -1
      if debit_note_action
        flag = true
      else
        flag = false
      end
    end
    return flag
  end

  def dn_can_be_approved? user
    last_dn_approval = GeneralSetting.where(desc: "Last DN Approval").first.value rescue "Supplier"
    last_dn_approval == "Supplier" && user.supplier.present? || last_dn_approval == "Customer" && user.warehouse.present?
  end

  def take_action(params,user)
    remark = params[:debit_note][:dn_remark] rescue ''
    begin
#      ActiveRecord::Base.transaction do
        save_debit_note = DebitNote.new(self.attributes.except("id","warehouse_id","supplier_id","state","created_at","updated_at","user_id"))
        save_debit_note.warehouse_id = self.warehouse_id
        save_debit_note.supplier_id = self.supplier_id
        save_debit_note.user_id = user.id
        save_debit_note.amount = self.amount
        if params[:from_action] == "accept" && self.can_accept?
          if self.dn_can_be_approved? user
            save_debit_note.state = 3
            prev_dn = self

            last_key = 0
            arr_seq_existed = []

            save_debit_note = DebitNote.new(prev_dn.attributes.except("id","warehouse_id","supplier_id","state","created_at","updated_at","user_id","dn_remark"))
            save_debit_note.insert_protected_attr(prev_dn,user, 3)
            save_debit_note.insert_product_id_to_po_details(prev_dn, arr_seq_existed)
          else
            save_debit_note.state = 6
            prev_dn = self

            last_key = 0
            arr_seq_existed = []

            save_debit_note = DebitNote.new(prev_dn.attributes.except("id","warehouse_id","supplier_id","state","created_at","updated_at","user_id","dn_remark"))
            save_debit_note.insert_protected_attr(prev_dn,user, 6)
            save_debit_note.insert_product_id_to_po_details(prev_dn, arr_seq_existed)
          end
        elsif params[:from_action] == "reject" && self.can_reject?
          save_debit_note.dn_remark = remark if remark.present?
          save_debit_note.state = 4
        elsif self.can_expire?
          save_debit_note.state = 5
        end
        if save_debit_note.save && self.update_attributes(:is_history => true)
          OffsetApi.push_data("b2bdebtrans", save_debit_note.prep_json) if self.dn_can_be_approved? user
          self.debit_note_lines.map(&:attributes).each_with_index do |v, k|
            save_debit_note.debit_note_lines.create v.delete_if{|a|%w(id debit_note_id created_at updated_at).include?a}
          end
          if self.dn_can_be_approved? user
            save_debit_note.debit_note_lines.each do |line|
              OffsetApi.push_data("b2bdebtransline", line.prep_json)
            end
          end

          PurchaseOrder.send_notifications(save_debit_note)
          if save_debit_note.debit_notes.blank?
            self.debit_notes.each do |dn|
              debit_note_detail = DebitNote.new(dn.attributes.except("id","warehouse_id","supplier_id","amount","state","created_at","updated_at","user_id","parent_id"))
              debit_note_detail.warehouse_id = dn.warehouse_id
              debit_note_detail.supplier_id = dn.supplier_id
              debit_note_detail.user_id = dn.user_id
              debit_note_detail.amount = dn.amount
              debit_note_detail.parent_id = save_debit_note.id
              debit_note_detail.save
            end
          end
        end
      end
#    rescue => e
 #     return false
  #    ActiveRecord::Rollback
   # end
  end

  def self.count_dn_statuses_today(current_user)
    if current_user.has_role?(:superadmin)
      dns = DebitNote.select("DISTINCT ON (order_number) order_number, debit_notes.id ,state,  debit_notes.transaction_date").order("order_number, debit_notes.updated_at desc").find(:all, :conditions=>["trans_type = ? and Date(debit_notes.transaction_date)=Date(?) and is_history=?", "IN", Time.now, false])
    elsif  current_user.supplier.present?
      if current_user.supplier.group.present? && current_user.roles.first.group_flag
        dns = DebitNote.joins(:supplier).select("DISTINCT ON (order_number) order_number, debit_notes.id ,state,  debit_notes.updated_at").order("order_number, debit_notes.updated_at desc").where("suppliers.group_id = #{current_user.supplier.group.id} and trans_type = ? and Date(debit_notes.updated_at)=Date(?) and is_history = ?", "IN", Time.now, false)
      else
        dns = DebitNote.select("DISTINCT ON (order_number) debit_notes.id ,state,  debit_notes.updated_at").order("order_number, debit_notes.updated_at desc").find(:all, :conditions=>["supplier_id = #{current_user.supplier.id} and trans_type = ? and Date(debit_notes.updated_at)=Date(?) and is_history = ?", "IN", Time.now, false])
      end
    else
      unless current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          dns = DebitNote.joins(:warehouse).select("DISTINCT ON (order_number) order_number, debit_notes.id ,state,  debit_notes.updated_at").order("order_number, debit_notes.updated_at desc").find(:all, :conditions=>["warehouses.group_id = #{current_user.warehouse.group.id} and trans_type = ? and Date(debit_notes.updated_at)=Date(?) and is_history = ?", "IN", Time.now, false])
        else
          dns = current_user.warehouse.debit_notes.select("DISTINCT ON (order_number) order_number, debit_notes.id ,state,  debit_notes.updated_at").order("order_number, debit_notes.updated_at desc").find(:all, :conditions=>["trans_type = ? and Date(debit_notes.updated_at)=Date(?) and is_history = ?", "IN", Time.now, false])
        end
      end
    end

    count = {:pending=>0, :disputed=>0, :revisioned=>0, :rejected=>0,:accepted=>0,:expired=>0, :for=>"#{DN}"}
    unless dns.blank?
      dns.each do |r|
        case r.state_name.to_s
          when "pending", "nil", ""
            count[:pending] +=1
          when "disputed"
            count[:disputed] +=1
          when "revisioned"
            count[:revisioned] +=1
          when "rejected"
            count[:rejected] +=1
          when "expired"
            count[:expired] +=1
          when "accepted"
            count[:accepted] +=1
        end
      end
    end
    return count
  end

  def self.count_disputed_dn(current_user)
    arr = {}
    if current_user.has_role?(:superadmin)
      arr[:disp_dns] = DebitNote.with_state(:disputed,:revisioned).where(" Date(debit_notes.created_at) = Date(?) and debit_notes.is_history = ?", Date.today, false).count
    elsif  !current_user.supplier.blank?
      if !current_user.supplier.group.blank?  && current_user.roles.first.group_flag
        arr[:disp_dns] = DebitNote.joins(:supplier).with_state(:disputed,:revisioned).where("suppliers.group_id = #{current_user.supplier.group.id} and Date(debit_notes.created_at) = Date(?) and debit_notes.is_history = ?", Date.today, false).count
      else
        arr[:disp_dns] = DebitNote.joins(:supplier).with_state(:disputed,:revisioned).where("debit_notes.supplier_id = #{current_user.supplier.id} and Date(debit_notes.created_at) = Date(?) and debit_notes.is_history = ?", Date.today, false).count
      end
    else
      unless current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          arr[:disp_dns] = DebitNote.joins(:warehouse).with_state(:disputed,:revisioned).where("warehouses.group_id = #{current_user.warehouse.group.id} and  Date(debit_notes.created_at) = Date(?) and debit_notes.is_history = ?", Date.today, false).count
        else
          arr[:disp_dns] = DebitNote.joins(:warehouse).with_state(:disputed,:revisioned).where("debit_notes.warehouse_id = #{current_user.warehouse.id} and Date(debit_notes.created_at) = Date(?) and debit_notes.is_history = ?", Date.today, false).count
        end
      end
    end
    return arr
  end

  def self.count_dns_statuses(date, state, current_user)
    arr = Array.new(13) { Array.new }
    dns = ''
    if current_user.has_role? :superadmin
      if state == "pending"
        dns = DebitNote.where("state IS NULL and trans_type = ? and to_char(transaction_date, 'YYYYMM') = ?", "IN", date)
      else
        dns = DebitNote.with_state(state.to_sym).where("trans_type = ? and to_char(debit_notes.created_at, 'YYYYMM') = ? and is_history= ?","IN", date, false).group_by(&:order_number)
      end
    elsif !current_user.supplier.blank?
      if !current_user.supplier.group.blank? && current_user.roles.first.group_flag
        if state == "pending"
          dns = DebitNote.joins(:supplier).where("state IS NULL and suppliers.group_id = #{current_user.supplier.group.id} and trans_type = ? and to_char(transaction_date, 'YYYYMM') = ?","IN", date)
        else
          dns = DebitNote.joins(:supplier).with_state(state.to_sym)
            .where("suppliers.group_id = #{current_user.supplier.group.id} and trans_type = ? and to_char(debit_notes.created_at, 'YYYYMM') = ? and is_history= ?","IN", date, false).group_by(&:order_number)
        end
      else
        if state == "pending"
          dns = DebitNote.where("supplier_id = #{current_user.supplier.id} and state IS NULL and trans_type = ? and to_char(invoice_date, 'YYYYMM') = ?","IN", date)
        else
          dns = DebitNote.with_state(state.to_sym).where("supplier_id = #{current_user.supplier.id} and trans_type = ? and to_char(debit_notes.created_at, 'YYYYMM') = ?","IN", date).group_by(&:order_number)
        end
      end
    elsif !current_user.warehouse.blank?
      if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
        if state == "pending"
          dns = DebitNote.joins(:warehouse).where("state IS NULL and warehouses.group_id = #{current_user.warehouse.group.id} and trans_type = ? and to_char(transaction_date, 'YYYYMM') = ?","IN", date)
        else
          dns = DebitNote.joins(:warehouse).with_state(state.to_sym)
            .where("warehouses.group_id = #{current_user.warehouse.group.id} and trans_type = ? and to_char(debit_notes.created_at, 'YYYYMM') = ? and is_history= ?","IN", date, false).group_by(&:order_number)
        end
      else
        if state == "pending"
          dns = current_user.warehouse.debit_notes.where("state IS NULL and trans_type = ? and to_char(transaction_date, 'YYYYMM') = ?","IN", date)
        else
          dns = current_user.warehouse.debit_notes.with_state(state.to_sym).where("trans_type = ? and to_char(debit_notes.created_at, 'YYYYMM') = ? and is_history= ?","IN", date, false)
        end
      end
    end
    return dns.size
  end

  def self.stats_of_all_dn_state(date, current_user)
    arr = {}
    if date.blank?
       date = Date.today.strftime("%Y%m")
    end
      arr[:pending] = DebitNote.count_dns_statuses(date, "pending", current_user)
      arr[:disputed] = DebitNote.count_dns_statuses(date, "disputed", current_user)
      arr[:revisioned] = DebitNote.count_dns_statuses(date, "revisioned", current_user)
      arr[:rejected] = DebitNote.count_dns_statuses(date, "rejected", current_user)
      arr[:expired] = DebitNote.count_dns_statuses(date, "expired", current_user)
      arr[:accepted] = DebitNote.count_dns_statuses(date, "accepted", current_user)
    return arr
  end

  def self.get_search_dn(params)
    where(:is_history => false).with_state(:accepted).with_payment_state(:unused).joins(:supplier).where("debit_notes.trans_type = ? AND suppliers.code LIKE '%#{params[:supplier]}%' OR suppliers.name LIKE '%#{params[:supplier]}%'", 'IN')
  end

  def self.find_dn_history param_id
    self.where(is_history: true, order_number: DebitNote.find(param_id).order_number).limit(1).order('id DESC')
  end

  def prep_json
    val = []
    val << "'b2b_accountcode': '#{supplier.code}'"
    # val << "'b2b_tr_sort_key': #{missing}"
    val << "'b2b_br_acc_code': '#{branch_number}'"
    val << "'b2b_trans_type': '#{trans_type}'"
    val << "'b2b_trans_date': '#{transaction_date}'"
    val << "'b2b_trans_ref': '#{reference}'"
    val << "'b2b_tr_details': '#{details}'"
    val << "'b2b_batch_ref': '#{batch}'"
#    val << "'b2b_shipped_amount': '#{total_amount_after_tax}'"
    # val << "'b2b_tr_amount': #{missing}"
    # val << "'b2b_terms_disc_amt': '#{missing}'"
    val << "'b2b_dr_tr_whse_code': '#{warehouse.warehouse_code}'"
    val << "'b2b_dr_tr_order_no': #{order_number}"
    val << "'b2b_dr_tr_bo_suffix': '#{suffix}'"
    # val << "'b2b_dr_tr_job_code': #{missing}"
    # val << "'b2b_rep_code1': #{missing}"
    # val << "'b2b_dr_tr_territory': #{missing}"
    # val << "'b2b_dr_tr_cost': #{missing}"
    # val << "'b2b_sundry_charges': #{missing}"
    # val << "'b2b_dr_tr_spare_num': #{missing}"
    # val << "'b2b_tax_e_amt': #{missing}"
    # val << "'b2b_non_t_amt': #{missing}"
    # val << "'b2b_tax_amt': #{missing}"
    # val << "'b2b_sales_tax_claim': #{missing}"
    # val << "'b2b_dr_tr_terms_disc': #{missing}"
    # val << "'b2b_dr_tr_os_amount': #{missing}"
    # val << "'b2b_dr_tr_curr_code': #{missing}"
    # val << "'b2b_dr_tr_date_stamp': #{updated_date}" # nil
    # val << "'b2b_dr_tr_time_stamp': #{updated_date}" # nil
    # val << "'b2b_dr_tr_user_id': #{missing}"
    # val << "'b2b_invoice_status': #{missing}"
    val << "'b2b_tr_invoice_date': '#{invoice_date}'"
    # val << "'b2b_invoice_source': #{missing}"
    val << "'b2b_dr_tr_due_date': '#{due_date}'"
    # val << "'b2b_dr_tr_trans_no': #{missing}"
    # val << "'b2b_tr_reported_date': #{missing}"
    # val << "'b2b_trans_desc_code': #{missing}"
    # val << "'b2b_tr_analysis_code': #{missing}"
    val << "'b2b_tr_document_type': '#{tracking_type}'"
    val << "'b2b_tr_document_no': '#{tracking_no}'"
    # val << "'b2b_document_suffix': #{missing}"
    # val << "'b2b_tr_document_seq': #{missing}"
    # val << "'b2b_financial_year': #{missing}"
    val << "'b2b_financial_period': '#{financial_period}'"
    # val << "'b2b_tr_record_status': #{missing}"
    val << "'b2b_flag': '#{DebitNote.where("state=1 AND order_number='#{order_number}'").count > 0 ? 2 : 1}'"
    val << "'b2b_flag_2': '#{DebitNote.where("state=1 AND order_number='#{order_number}'").count > 0 ? 2 : 1}'"

    return "{#{val.join(",").gsub!("'", '"')}}"
  end
end
