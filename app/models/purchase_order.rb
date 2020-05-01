class PurchaseOrder < ActiveRecord::Base
  belongs_to :user
  belongs_to :supplier
  belongs_to :warehouse
  has_many :returned_processes
  has_many :details_purchase_orders
  has_many :payment_voucher_details
  has_many :stock_serial_links, :primary_key => "po_number", :foreign_key => "serial_link_code"
  has_many :early_payment_requests
  has_many :service_level_histories
  has_many :user_logs, :as => :log
  has_many :inv_histories
  require 'open-uri'
  include ApplicationHelper
  include ActionView::Helpers::NumberHelper

  accepts_nested_attributes_for :stock_serial_links, :allow_destroy => true, :reject_if => proc { |obj| !obj.purchase_order.order_type.eql? GRN }
  accepts_nested_attributes_for :details_purchase_orders, :allow_destroy => true, :reject_if => proc { |obj| obj.blank? }
  validates :invoice_number, :presence=>{:message => "Invoice Number can't be blank.", :allow_blank => true}, length: { maximum: 25, :message=> "maximum 19 character reached" }
  validates :tax_invoice_number, length: { maximum: 19, :allow_blank=>true, :allow_nil=>true, :message=> "maximum 19 character reached" }
  validates_associated :details_purchase_orders
  #include PublicActivity::Model
  #tracked
  # after_save :save_activity
  attr_accessible :details_purchase_orders_attributes,:po_from, :po_date, :asn_delivery_date, :received_date,
                  :po_number, :grn_number, :asn_number, :grpc_number, :invoice_number, :order_type, :order_status,
                  :invoice_barcode, :total_qty, :po_type, :po_remark,
                  :tax_invoice_number, :tax_invoice_date, :tax_invoice_remark,
                  :is_closed, :due_date, :is_suffix,:is_suffiix, :ordered_total,
                  :received_total,:total_line_qty,:charges_total,:ordered_tax_amt,:received_tax_amt,:invoice_date,:invoice_due_date,
                  :pay_by_date, :inv_print_count, :is_payment_voucher_completed, :user_name,
                  :warehouse_desc, :supplier_desc, :term, :currency_code, :initial_currency_rate, :is_create_payment_request,
                  :updated_date, :updated_time, :backorder_flag, :is_completed_invoice_to_api, :asn_state, :user_id
  attr_protected :supplier_id, :warehouse_id, :state, :grn_state, :grpc_state, :inv_state, :is_published, :is_completed, :is_history
  #for a moment, state for po just for po, asn, grn and grpc. For invoice others and is coming right up

#====================================================================================================
#================ IMPORTANT ============================
#status rev = rejected untuk GRN, GRPC
#====================================================================================================

  state_machine :grn_state, :initial => :nil, :namespace => 'grn' do
    after_transition :on => :raise_dispute, :do => :save_activity
    after_transition :on => :resolve, :do => :save_activity
    after_transition :on => :accept, :do => :save_activity

    event :to_unread do
      transition :nil => :new,:if => lambda {|po| po.order_type == "#{GRN}"}
    end
    event :read do
      transition :new => :read
    end
    event :raise_dispute do
      transition [:read, :rev] => :dispute, :if => lambda {|po| po.count_rev_of("#{GRN}") <= 20 }
    end
    event :resolve do
      transition :dispute => :rev
    end
    event :pending do
      transition [:read, :rev, :dispute] => :pending
    end
    event :accept do
      transition [:read, :rev, :dispute, :pending] => :accepted
    end
    event :expire do
       transition [:read, :dispute, :rev] => :expired, :if => lambda {|po| po.due_date > Date.now }
    end
    state :nil, :value => 0
    state :new, :value => 1
    state :read, :value => 2
    state :dispute, :value => 3
    state :rev, :value=> 4
    state :accepted, :value => 5
    state :expired, :value => 6
    state :pending, :value => 7
  end

  #state for asn
  state_machine :asn_state, :initial => :new, :namespace => 'asn' do
    event :to_read do
      transition :new => :read,:if => lambda {|po| po.order_type == "#{ASN}"}
    end
    event :customer_edit do
      transition [:new, :read, :supplier_edited] => :customer_edited
    end
    event :supplier_edit do
      transition [:customer_edited] => :supplier_edited
    end
    event :accept do
      transition [:new, :read, :customer_edited, :supplier_edited] => :accepted
    end
    event :cancelled_po do
      transition [:new, :read, :customer_edited, :supplier_edited] => :cancelled
    end
    state :new, :value => 1
    state :read, :value => 2
    state :customer_edited, :value => 3
    state :supplier_edited, :value => 4
    state :accepted, :value => 5
    state :canceled, :value => 6
  end

  #state for grpc
  state_machine :grpc_state, :initial => :nil, :namespace => 'grpc' do
    after_transition :on => :raise_dispute, :do => :save_activity
    after_transition :on => :revise, :do => :save_activity
    after_transition :on => :accept, :do => :save_activity

    event :to_unread do
        transition :nil => :unread,:if => lambda {|po| po.order_type == "#{GRPC}"}
    end
    event :read do
      transition :unread => :read
    end
    event :raise_dispute do
      transition [:read, :rev] => :dispute, :if => lambda {|po| po.count_rev_of("#{GRPC}") <= 20 }
    end
    event :revise do
      transition [:dispute] => :rev
    end
    event :pending do
      transition [:read, :rev, :dispute] => :pending
    end
    event :accept do
      transition [:read, :rev, :dispute, :pending] => :accepted
    end

    state :nil, :value => 0
    state :unread, :value => 1
    state :read, :value => 2
    state :dispute, :value => 3
    state :rev, :value => 4
    state :accepted, :value => 5
    state :pending, :value => 6
  end

  #state for respective po
  state_machine :state, initial: :new do
    state :new, value: 0
    state :open, value: 1
    state :on_time, value: 2
    state :on_time_but_less_than_100, value: 3
    state :late, value: 4
    state :late_but_less_than_100, value: 5
    state :expired, value: 6
    state :cancelled, value: 7

    after_transition :on => :open_po, :do => :save_activity
    event :open_po do
      transition :new => :open
    end
    event :fulfill_ontime do
      transition :open => :on_time
    end
    event :fulfill_po_less do
      transition [:open,:on_time] => :on_time_but_less_than_100
    end
    event :fulfill_po_late do
      transition :open => :late
    end
    event :fulfill_po_late_less do
      transition [:open,:late] => :late_but_less_than_100
    end
    event :expire_po do
      transition :new => :expired
    end
    event :cancelled_po do
      transition [:new, :open, :on_time] => :cancelled
    end
  end
  #state for invoice po
  state_machine :inv_state, :initial=>:nil, :namespace=>"inv" do
    after_transition :on => :print, :do => :save_activity
    after_transition :on => :receive, :do => :save_activity
    after_transition :on => :receive_incomplete, :do => :save_activity

    event :to_unlock do
      transition :nil => :new, :if => lambda {|po| po.order_type == "#{INV}" }
    end
    event :print do
      transition [:new,:incomplete] => :printed
    end
    event :receive do
      transition [:printed] => :completed, :if=> lambda {|po| po.po_remark.blank?}
    end
    event :receive_incomplete do
      transition [:printed] => :incomplete, :if => lambda {|po| !po.po_remark.blank?}
    end
    event :reject do
      transition [:printed] => :rejected
    end

    state :nil, :value=>0
    state :new, :value =>1
    state :printed, :value => 2
    state :rejected, :value=>3
    state :incomplete, :value=>4
    state :completed, :value=>5
  end

  scope :where_status_grn, lambda {|*state| {:conditions => {:grn_state => state}}}
  scope :where_status_asn, lambda {|*state| {:conditions => {:asn_state => state}}}
  scope :where_status_grpc, lambda {|*state| {:conditions => {:grpc_state => state}}}
  scope :where_status_inv, lambda {|*state| {:conditions => {:inv_state => state}}}
  scope :find_order_type, lambda {|id, type| {:conditions => {:id => id, :is_history=>false, :order_type => "#{type}", :is_completed=>true}}}
  scope :find_history_grn, lambda {|id| {:conditions=>{:id=>id, :order_type=>"#{GRN}", :grn_state=>[3,4,5], :is_completed=>true}}}
  scope :find_history_inv, lambda {|id| {:conditions=>{:id=>id, :order_type=>"#{INV}", :grn_state=>[3,4,5], :is_completed=>true}}}
  scope :find_history_grpc, lambda {|id| {:conditions=>{:id=>id, :order_type=>"#{GRPC}", :grpc_state=>[3,4,5], :is_completed=>true}}}
  scope :get_completed_payment_voucher, lambda {|is_payment_voucher_completed| {:conditions => {:is_payment_voucher_completed => is_payment_voucher_completed}}}
  paginates_per PER_PAGE

  def change_status
    self
  end

  def process_print_inv(params, user)
    prev_grn = self
    last_key = 0
    arr_seq_existed = []
    params[:purchase_order].merge!(prev_grn.attributes.except("id", "updated_at", "created_at","po_remark", "is_history", "supplier_id", "warehouse_id", "user_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed"))

    new_dispute_grn = PurchaseOrder.new(params[:purchase_order])
    new_dispute_grn.inv_state = 2
    new_dispute_grn.insert_protected_attr(prev_grn,user)

    prev_grn.is_history = true
    begin
      ActiveRecord::Base.transaction do
        if new_dispute_grn.save && prev_grn.save
          details_purchase_orders.map(&:attributes).each_with_index do |v, k|
            new_dispute_grn.details_purchase_orders.create v.delete_if{|a|%w(id purchase_order_id created_at updated_at).include?a}
          end
        end
      end
      PurchaseOrder.send_notifications(new_dispute_grn)
      return new_dispute_grn
    rescue => e
      ActiveRecord::Rollback
    end

    return false
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

    if self.order_type == GRN || self.order_type == INV
      left_header_template = ["PO Number","GRN Number","Warehouse","Supplier Code","Supplier Name","Order Type","Ordered","Arrival","Received Date"]
      sheet1 = book.create_worksheet :name => "#{GRN}"
      self_order = PurchaseOrder.where(:grn_number => self.grn_number, :order_type => "#{GRN}").where("grn_state in (3,4,5)").order("created_at ASC")
      #diambil data GRN yang last untuk accepted
      details_accepted = self_order.last.details_purchase_orders.order("seq ASC")
      details_title = ["Seq","Item Code","Barcode","Item Description","Commited QTY","Received QTY","Dispute QTY","UoM","Remark"]
    elsif self.order_type == ASN
      left_header_template = ["PO Number","GRN Number","Warehouse","Supplier Code","Supplier Name","Order Type","Ordered","Arrival","Received Date"]
      sheet1 = book.create_worksheet :name => "#{GRN}"
      self_order = PurchaseOrder.where(:po_number => self.po_number, :order_type => "#{ASN}").order("created_at ASC")
      #diambil data GRN yang last untuk accepted
      details_accepted = self_order.last.details_purchase_orders.order("seq ASC")
      details_title = ["Seq","Item Code","Barcode","Item Description","Commited QTY","Received QTY","Dispute QTY","UoM","Remark"]
    elsif self.order_type == GRPC
      left_header_template = ["PO Number","GRPC Number","Warehouse","Supplier Code","Supplier Name","Order Type","Ordered","Arrival","Received Date"]
      sheet1 = book.create_worksheet :name => "#{GRPC}"
      self_order = PurchaseOrder.where(:grpc_number => self.grpc_number, :order_type => "#{GRPC}").where("grpc_state in (3,4,5)").order("created_at ASC")
      #diambil data GRPC yang last untuk accepted
      details_accepted = self_order.last.details_purchase_orders.order("seq ASC")
      details_title = ["Seq","Item Code","Barcode","Item Description","Commited QTY","Received QTY","UoM","Item Price","Dispute Price","Remark"]
    elsif self.order_type == PO
      left_header_template = ["PO Number", "Warehouse", "Ship To", " Order Type", "Officer", "Supplier Code", "Supplier Name", "Phone Number", "Ordered", "Arrival", "Last Update By"]
      sheet1 = book.create_worksheet :name => "#{GRPC}"
      self_order = PurchaseOrder.where(:po_number => self.po_number, :order_type => "#{PO}").order("created_at ASC")
      #diambil data GRPC yang last untuk accepted
      details_accepted = self_order.last.details_purchase_orders.order("seq ASC")
      details_title = ["Seq","Item Code","Barcode","Item Description","Commited QTY","Received QTY","UoM","Item Price","Dispute Price","Remark"]
    end

#========================== HEADER ====================================
    9.times do |t|
      # ============  LEFT HEADER
      #column 0
      sheet1.row(t).default_format = column_bold
      sheet1[t, 0] = left_header_template[t]
    end

    # ============= VALUE LEFT HEADER
    sheet1[0, 2] = self.po_number
    if self.order_type == GRN
      sheet1[1, 2] = self.grn_number
    elsif self.order_type == GRPC
      sheet1[1, 2] = self.grpc_number
    end
    sheet1[2, 2] = self.warehouse.warehouse_name
    sheet1[3, 2] = self.supplier.code
    sheet1[4, 2] = self.supplier.name
    sheet1[5, 2] = self.order_type
    sheet1[6, 2] = convert_date(self.po_date)
    sheet1[7, 2] = convert_date(self.due_date)
    sheet1[8, 2] = convert_date(self.received_date)
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
      if self.order_type == GRN
        sheet1[i, 1] = s.grn_state_name.to_s == "rev" ? "Rejected #{s.revision_to}" : s.grn_state_name.to_s.capitalize
      elsif self.order_type == GRPC
        sheet1[i, 1] = s.grpc_state_name.to_s == "rev" ? "Rejected #{s.revision_to}" : s.grpc_state_name.to_s.capitalize
      elsif self.order_type == PO
        sheet1[i, 1] = s.state_name.to_s.capitalize
      end
      sheet1[i, 2] = convert_date(s.created_at)
      sheet1[i, 3] = s.created_at.to_datetime.new_offset(Rational(7,24)).strftime("%H:%M:%S")
      sheet1[i, 4] = "#{s.user.first_name} #{s.user.last_name}" rescue ''
      sheet1[i, 5] = s.po_remark
      sheet1.row(i).default_format = details_column
    end
  #======================================================================
    index += 2
    sheet1.row(index).default_format = other_column
    sheet1[index, 0] = "Disputed Lines"

  #===================== DETAIL TRANSACTION ACCEPTED ====================
    if self.order_type == GRN
      index += 1
      10.times do |d|
        sheet1[index, d] = details_title[d]
        sheet1.row(index).default_format = column_bold
      end
    elsif self.order_type == GRPC
      index += 1
      11.times do |d|
        sheet1[index, d] = details_title[d]
        sheet1.row(index).default_format = column_bold
      end
    end

    index += 1
    index2 = index
    total_price, total_dispute_price = 0, 0
    details_accepted.each_with_index do |d,i|
      sheet1[index+i,0] = d.seq
      sheet1[index+i,1] = d.product.code
      sheet1.column(1).width = 15
      sheet1[index+i,2] = d.product.apn_number
      sheet1.column(2).width = d.product.apn_number.to_s.length + 5
      sheet1[index+i,3] = d.product.name.gsub("<br/>","; ")
      sheet1[index+i,4] = d.commited_qty.to_i
      if self.order_type == GRN
        if d.received_qty != d.dispute_qty.to_i
          sheet1.row(index+i).default_format = disputed_grn_grpc
        else
          sheet1.row(index+i).default_format = details_column
        end
        sheet1[index+i,5] = d.received_qty.to_i
        sheet1[index+i,6] = d.remark.blank?? 0 : d.dispute_qty.to_i
        sheet1[index+i,7] = d.product.unit_description
        sheet1[index+i,8] = d.remark.blank?? "-OK-" : d.remark
      elsif self.order_type == GRPC
        if d.item_price != d.dispute_price
          sheet1.row(index+i).default_format = disputed_grn_grpc
          sheet1.row(index+i).set_format(7, curr_format)
          sheet1.row(index+i).set_format(8, curr_format)
        else
          sheet1.row(index+i).default_format = details_column
          sheet1.row(index+i).set_format(7, curr_format_yellow)
          sheet1.row(index+i).set_format(8, curr_format)
        end
        sheet1[index+i,5] = d.dispute_qty.to_i
        sheet1[index+i,6] = d.product.unit_description

        sheet1[index+i,7] = d.item_price
        sheet1.column(7).width = 20

        sheet1[index+i,8] = d.remark.blank?? 0 : d.dispute_price
        sheet1.column(8).width = 20

        sheet1[index+i,9] = d.remark.blank?? "-OK-" : d.remark

        total_price += d.item_price
        total_dispute_price += d.dispute_price
      end
      index2 += 1
    end
  #======================================================================
    if self.order_type == GRN ||  self.order_type == ASN ||  self.order_type == PO || self.order_type == INV
      path = "#{Rails.root}/public/purchase_order_xls/grn_excel-file.xls"
    elsif self.order_type == GRPC
      index2 += 1
      sheet1[index2, 6] = "Total Price"
      sheet1[index2, 7] = total_price
      sheet1[index2, 8] = total_dispute_price
      sheet1.row(index2).default_format = cur_total_format
      path = "#{Rails.root}/public/purchase_order_xls/grpc_excel-file.xls"
    end

    book.write path
    return path
  end

  def grpc_not_max_round current_user
    PurchaseOrder.where("user_id=#{current_user.id} AND grpc_number='#{grpc_number}'").count < DisputeSetting.find_by_transaction_type('GRPC').max_round-1
  end

  def save_activity
    state_name_status = ""
    unless self.order_type == "#{ASN}"
      case self.order_type
        when "#{PO}"
          unless self.state_name.to_s == "nil"
            state_name_status = self.state_name.to_s
          else
            state_name_status = nil
          end
        when "#{GRN}"
          unless self.grn_state_name.to_s == "nil"
            state_name_status = self.grn_state_name.to_s
          else
            state_name_status = nil
          end
        when "#{GRPC}"
          unless self.grpc_state_name.to_s == "nil"
            state_name_status = self.grpc_state_name.to_s
          else
            state_name_status = nil
          end
        when "#{INV}"
          unless self.inv_state_name.to_s == "nil"
            state_name_status = self.inv_state_name.to_s
          else
            state_name_status = nil
          end
      end

      unless state_name_status.blank?
        ul = UserLog.new(:log_type => self.class.model_name, :event => state_name_status, :transaction_type => "#{self.order_type}" )
        ul.user_id = self.user_id
        ul.log_id = self.id
        ul.save
      end
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

  def self.check_between_two_date(period_1,period_2)
    date1 = PurchaseOrder.is_period_blank(period_1)
    return false if date1.blank?
    date2 = PurchaseOrder.is_period_blank(period_2)
    return false if date2.blank?
    return true if date1 == date2
  end

  def self.search_report(options, user=nil)
    order_type = options[:search][:order_type]
    status = options[:search][:detail].split(" ").join("_")
    unless options[:search].blank?
      if options[:search][:field].present?
        unless options[:search][:detail].blank?
          case options[:search][:field].downcase
          when 'order number'
            res = where("po_number ilike ? ", "%#{options[:search][:detail]}%" )
          when 'grpc number'
            res = where("grpc_number ilike ?", "%#{options[:search][:detail]}%" )
          when 'grn number'
            res = where("grn_number ilike ? ", "%#{options[:search][:detail]}%" )
          when 'invoice number'
            res = where("invoice_number ilike ? ", "%#{options[:search][:detail]}%" )
          when "status"
            begin
              case order_type
                when "purchase_orders"
                  o_type = "#{PO}"
                  res = with_state(status.to_sym)
                  res = res.where("order_type = ?", "#{PO}")
                when "goods_receive_notes"
                  o_type = "#{GRN}"
                  res = with_grn_state(status.to_sym)
                  res = res.where("order_type = ?", "#{GRN}")
                when "goods_receive_price_confirmations"
                  o_type = "#{GRPC}"
                  res = with_grpc_state(status.to_sym)
                  res = res.where("order_type = ?", "#{GRPC}")
                when "invoices"
                  o_type = "#{INV}"
                  res = with_inv_state(status.to_sym)
                  res = res.where("order_type = ?", "#{INV}")
              end
            rescue => e
              case order_type
                when "purchase_orders"
                  res = where("order_type = ? AND state IS NULL", "#{PO}")
                when "goods_receive_notes"
                  res = where("order_type = ? AND grn_state IS NULL", "#{GRN}")
                when "goods_receive_price_confirmations"
                  res = where("order_type = ? AND grpc_state IS NULL", "#{GRPC}")
                when "invoices"
                  res = where("order_type = ? AND inv_state IS NULL", "#{INV}")
              end
            end
          end
        else
          res = where("order_type = ? AND state IS NULL", "#{PO}") if order_type == "purchase_orders"
          res = where("order_type = ? AND grn_state IS NULL", "#{GRN}") if order_type == "goods_receive_notes"
          res = where("order_type = ? AND grpc_state IS NULL", "#{GRPC}") if order_type == "goods_receive_price_confirmations"
          res = where("order_type = ? AND inv_state IS NULL", "#{INV}") if order_type == "invoices"
        end

        if user.try(:supplier).present?
          if user.try(:supplier).try(:group).present? && user.roles.first.try(:group_flag)
            res = res.joins(:supplier).where("suppliers.group_id = ?", user.supplier.group.id)
          else
            res = res.joins(:supplier).where("purchase_orders.supplier_id = ?", user.supplier.id)
          end
        elsif user.try(:warehouse).present?
          if user.try(:warehouse).try(:group).present? && user.roles.first.try(:group_flag)
            res = res.joins(:warehouse).where("warehouses.group_id = ?", user.warehouse.group.id)
          else
            res = res.joins(:warehouse).where("purchase_orders.warehouse_id = ?", user.warehouse.id)
          end
        end

        case order_type
        when "invoices"
          period_date = "DATE(purchase_orders.created_at)"
        when "debit_notes"
          period_date = "DATE(debit_notes.created_at)"
        else
          period_date = "DATE(purchase_orders.po_date)"
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
            case order_type
              when "purchase_orders"
                res = with_states(*status)
              when "goods_receive_notes"
                res = with_grn_states(*status)
              when "goods_receive_price_confirmations"
                res = with_grpc_states(*status)
              when "invoices"
                res = with_inv_states(*status)
              when "advance_shipment_notifications"
                res = with_asn_states(*status)
            end
            rescue => e
              return res = where(:state=>nil) #return empty array active record if state does not included valid state
          end
        end
        case order_type
        when "invoices", "debit_notes"
          period_date = "DATE(purchase_orders.created_at)"
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

  #function search for grn
  def self.asn_search(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'asn number'
          where("po_number ilike ? and order_type ilike ?", "%#{options[:search][:detail]}%", "%#{ASN}%")
        when "status"
          t = asn_status(options[:search][:detail].downcase)
          where_status_asn(t)
        end
      else
         where("asn_number ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      scoped
    end
  end

  #function search for grn
  def self.grn_search(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'grn number'
          where("po_number ilike ? and order_type ilike ? ", "%#{options[:search][:detail]}%", "%#{GRN}%")
        when "status"
          t = grn_status(options[:search][:detail].downcase)
          where_status_grn(t)
        end
      else
         where("grpc_number ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      scoped
    end
  end

  #function for search for grpc
  def self.grpc_search(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'grpc number'
          where("po_number ilike ? and order_type ilike ?", "%#{options[:search][:detail]}%", "%#{GRPC}%")
        when "status"
          t = grn_status(options[:search][:detail].downcase)
          where_status_grpc(t)
        end
      else
         where("grn_number ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      scoped
    end
  end
  #search function for invoices
  def self.inv_search(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        where("")
        case options[:search][:field].downcase
        when 'order number'
          where("po_number ilike ? and order_type ilike ?", "%#{options[:search][:detail]}%", "%#{INV}%")
        when "status"
          t = inv_status(options[:search][:detail].downcase)
          where_status_inv(t)
        end
      else
         where("invoice_number ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      scoped
    end
  end

  def self.where_supplier_name(options)
    select("DISTINCT ON (purchase_orders.po_number) purchase_orders.po_number, purchase_orders.id as po_id, purchase_orders.created_at, purchase_orders.*, suppliers.code").where("suppliers.name ilike ? and purchase_orders.order_type = ?", "%#{options[:supplier_name]}%", "#{INV}").joins(:supplier)
  end

  #function for search invoice where is last action
  def self.completed_inv_search(options)
    options = options.reject{|k,v| k == "_" || k == "action" || k == "controller" || k == "supplier_id"}
    if options[:Supplier_Code].present? || options[:PO_Number].present? || options[:GRN_Number].present? || options[:Invoice_Number].present? || options[:Payment_Invoice_Due_Date].present?
      options.each do |k, v|
        case k.downcase
          when 'supplier_code'
            return where("suppliers.code ilike ? and purchase_orders.order_type = ?", "%#{v}%", "#{INV}")
          when 'po_number'
            return where("purchase_orders.po_number ilike ? and purchase_orders.order_type = ?", "%#{v}%", "#{INV}")
          when 'grn_number'
            return where("purchase_orders.grn_number ilike ? and purchase_orders.order_type = ?", "%#{v}%", "#{INV}")
          when 'invoice_number'
            return where("purchase_orders.invoice_number ilike ? and purchase_orders.order_type = ?", "%#{v}%", "#{INV}")
          when 'payment_invoice_due_date'
            yr = v.split("-")[2].to_i
            mt = v.split("-")[1].to_i
            dd = v.split("-")[0].to_i
            join_date = "#{yr}-#{mt}-#{dd}".to_date
            return where("DATE(purchase_orders.payment_invoice_due_date) = ?", join_date)
        end
      end
    else
      scoped
    end
  end

  #function for create asn if asn draft not found
  def self.save_asn
    if asn.asn_saved?
      return true
    else
      return false
    end
  end

  def insert_protected_attr(parent, user=nil)
     self.supplier_id = parent.supplier_id
     self.warehouse_id = parent.warehouse_id
     unless user.blank?
       self.user_id = user.id
     else
       self.user_id = parent.user_id
     end
     self.grn_state = parent.grn_state
     self.asn_state = parent.asn_state
     self.is_published = parent.is_published
     self.is_history = parent.is_history
     self.grpc_state = parent.grpc_state
     self.inv_state = parent.inv_state
     self.is_completed = parent.is_completed
     self.updated_date = parent.updated_date
     self.updated_time = parent.updated_time
  end

  def insert_product_id_to_po_details(parent, seq=[])
    unless seq.blank?
      seq.each_with_index do |seq, i|
        det = parent.details_purchase_orders.where(:seq => seq).last
        self.details_purchase_orders[i].product_id = det.product_id
#        current_po = PurchaseOrder.find_by_po_number_and_order_type(po_number, 'Purchase Order')
#        prod_by_po = DetailsPurchaseOrder.find_by_purchase_order_id_and_product_id(current_po.id, det.product_id)
#        if order_type == 'Invoice' && 
      end
    end
  end

  #this function is used to prep params for new blank asn object
  def self.fill_for_new_blank_asn(params, user)
    parent = PurchaseOrder.find_order_type(params[:id], "#{PO}").last
    if parent.blank?
       asn = false
       return asn
    end
    params[:purchase_order].merge!(parent.attributes.except("id", "updated_at", "created_at", "supplier_id", "warehouse_id", "user_id", "state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed","asn_delivery_date"))
    parent.details_purchase_orders.order("seq ASC").each_with_index do |d, index|
      params[:purchase_order][:details_purchase_orders_attributes][index.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id","commited_qty","product_id")
    end
    asn = PurchaseOrder.new(params[:purchase_order])
    asn.insert_protected_attr(parent, user)
    parent.details_purchase_orders.order("seq ASC").each_with_index do |d, index|
      asn.details_purchase_orders[index].product_id = d.product_id
    end
    send_notifications(asn)
    return asn
  end

  #this function is used to create revised grn from disputed one
  def self.create_revised_grn(prev_grn,params, user)
    last_key = 0
    arr_seq_existed = []
    revision_to = self.where(:grn_number => "#{prev_grn.grn_number}").with_grn_state(:rev).count + 1
    disputed_grn = prev_grn
    params[:purchase_order].merge!(disputed_grn.attributes.except("id", "updated_at", "created_at", "po_remark", "is_history", "supplier_id","warehouse_id","user_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed"))

    params[:purchase_order][:details_purchase_orders_attributes].each do |k, v|
      det = disputed_grn.details_purchase_orders.where(:seq => v["seq"].to_i).last
      params[:purchase_order][:details_purchase_orders_attributes][k].merge! det.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id","seq")
      arr_seq_existed << det.seq
      last_key = k.to_i
    end

    undisputed = disputed_grn.details_purchase_orders.where("seq NOT IN (#{arr_seq_existed.join(',')})").order("seq ASC")
    undisputed.each do |d|
      last_key += 1
      params[:purchase_order][:details_purchase_orders_attributes].merge!({"#{last_key}" => {"remark" => "#{d.remark}"}})
      params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id")
      arr_seq_existed << d.seq
    end

    new_revised_grn = PurchaseOrder.new(params[:purchase_order])
    new_revised_grn.insert_protected_attr(disputed_grn, user)
    new_revised_grn.insert_product_id_to_po_details(disputed_grn, arr_seq_existed)
    new_revised_grn.revision_to = revision_to
    disputed_grn.is_history= true
    begin
      ActiveRecord::Base.transaction do
        if new_revised_grn.save && disputed_grn.save
          new_revised_grn.resolve_grn if new_revised_grn.can_resolve_grn?
        end
      end
      send_notifications(new_revised_grn)
      return new_revised_grn
    rescue => e
      ActiveRecord::Rollback
    end

    return false
  end

  #this function is used to create a dispute grn
  def self.create_disputed_grn(prev_grn,params,user)
    last_key = 0
    arr_seq_existed = []
    params[:purchase_order].merge!(prev_grn.attributes.except("id", "updated_at", "created_at","po_remark", "is_history", "supplier_id", "warehouse_id", "user_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed"))

    params[:purchase_order][:details_purchase_orders_attributes].each do |k, v|
      det = prev_grn.details_purchase_orders.where(:seq => v["seq"].to_i).last
      params[:purchase_order][:details_purchase_orders_attributes][k].merge! det.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id","dispute_qty", "seq")
      arr_seq_existed << det.seq
      last_key = k.to_i
    end

    undisputed = prev_grn.details_purchase_orders.where("seq NOT IN (#{arr_seq_existed.join(',')})").order("seq ASC")
    undisputed.each do |d|
      last_key += 1
      params[:purchase_order][:details_purchase_orders_attributes].merge!({"#{last_key}" => {"remark" => "#{d.remark}", "dispute_qty" => d.dispute_qty, "is_disputed" => false, "seq" => d.seq}})
      params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id","dispute_qty")
      arr_seq_existed << d.seq
    end

    new_dispute_grn = PurchaseOrder.new(params[:purchase_order])
    new_dispute_grn.insert_protected_attr(prev_grn,user)
    new_dispute_grn.insert_product_id_to_po_details(prev_grn, arr_seq_existed)
    prev_grn.is_history = true
    begin
      ActiveRecord::Base.transaction do
        if new_dispute_grn.save && prev_grn.save
          new_dispute_grn.raise_dispute_grn if new_dispute_grn.can_raise_dispute_grn?
        end
      end
      send_notifications(new_dispute_grn)
      return new_dispute_grn
    rescue => e
      ActiveRecord::Rollback
    end

    return false
  end

  #this function is used to insert details parent grn to new prep grn
  def insert_details_grn_or_grpc(params)
    self.details_purchase_orders.order("seq ASC").each_with_index do |d, index|
      params[:details_purchase_orders_attributes][index.to_s][:id] = d.id
    end
  end

  #this function is used to create an accepted grn
  def self.accept_grn(prev_grn,params,user)
    last_key = 0
    arr_seq_existed = []
    params[:purchase_order].merge!(prev_grn.attributes.except("id", "updated_at", "created_at","po_remark", "is_history", "supplier_id", "warehouse_id", "user_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed"))
    #dibawah ini kode baru untuk accept GRN
    params[:purchase_order][:details_purchase_orders_attributes].each do |k, v|
      det = prev_grn.details_purchase_orders.where(:seq => v["seq"].to_i).last
      params[:purchase_order][:details_purchase_orders_attributes][k].merge! det.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id","dispute_qty", "seq")
      arr_seq_existed << det.seq
      last_key = k.to_i
    end

    unless arr_seq_existed.blank?
      undisputed = prev_grn.details_purchase_orders.where("seq NOT IN (#{arr_seq_existed.join(',')})").order("seq ASC")
      undisputed.each do |d|
        last_key += 1
        params[:purchase_order][:details_purchase_orders_attributes].merge!({"#{last_key}" => {"remark" => "#{d.remark}", "dispute_qty" => d.dispute_qty, "is_disputed" => false, "seq" => d.seq}})
        params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id","dispute_qty")
        arr_seq_existed << d.seq
      end
    end
    #==========================
    params[:purchase_order].merge! prev_grn.attributes.except("id", "created_at","updated_at","po_remark", "is_history","supplier_id","warehouse_id","user_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed")
    new_accepted_grn = PurchaseOrder.new params[:purchase_order]
    new_accepted_grn.insert_protected_attr(prev_grn, user)
    new_accepted_grn.insert_product_id_to_po_details(prev_grn, arr_seq_existed)
    total_qty=0

    params[:purchase_order][:details_purchase_orders_attributes].each do |detail|
      detail[1][:remark]= nil if detail[1].has_key?(:remark)
      total_qty += detail[1][:dispute_qty].to_f
    end

    new_grpc = PurchaseOrder.new params[:purchase_order]
    new_grpc.total_qty = total_qty
    new_grpc.po_remark = ''
    new_grpc.grpc_number = prev_grn.grn_number
    new_grpc.insert_protected_attr(prev_grn, user)
    new_grpc.insert_product_id_to_po_details(prev_grn, arr_seq_existed)
    prev_grn.is_history = true
    new_grpc.po_to_?

    begin
      ActiveRecord::Base.transaction do
        if new_accepted_grn.save && new_grpc.save && prev_grn.save
          new_accepted_grn.count_service_level(prev_grn)
          new_accepted_grn.accept_grn if new_accepted_grn.can_accept_grn?
          new_grpc.accept_grn if new_grpc.can_accept_grn?
        end
      end
      send_notifications(new_accepted_grn)
      send_notifications(new_grpc)
      return new_accepted_grn
    rescue => e
      ActiveRecord::Rollback
    end

    return false
  end

  #this function is used to create pending grpc
  def self.pending_grpc(prev_grpc,params,user)
    last_key = 0
    arr_seq_existed = []
    params[:purchase_order].merge! prev_grpc.attributes.except("id", "created_at","updated_at","po_remark", "is_history","user_id","supplier_id","warehouse_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed")
    #dibawah ini kode baru untuk accept GRPC
    params[:purchase_order][:details_purchase_orders_attributes].each do |k, v|
      det = prev_grpc.details_purchase_orders.where(:seq => v["seq"].to_i).last
      params[:purchase_order][:details_purchase_orders_attributes][k].merge! det.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id", "seq")
      arr_seq_existed << det.seq
      last_key = k.to_i
    end

    unless arr_seq_existed.blank?
      undisputed = prev_grpc.details_purchase_orders.where("seq NOT IN (#{arr_seq_existed.join(',')})").order("seq ASC")
      undisputed.each do |d|
        last_key += 1
        params[:purchase_order][:details_purchase_orders_attributes].merge!({"#{last_key}" => {"remark" => "#{d.remark}", "dispute_price" => d.dispute_price, "is_disputed" => false, "seq" => d.seq}})
        params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id")
        arr_seq_existed << d.seq
      end
    end
    #==========================
    params[:purchase_order].merge! prev_grpc.attributes.except("id", "created_at","updated_at","po_remark", "is_history","user_id","supplier_id","warehouse_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed")
    new_accepted_grpc = PurchaseOrder.new params[:purchase_order]
    new_accepted_grpc.insert_protected_attr(prev_grpc,user)
    new_accepted_grpc.grpc_state = 6
    new_accepted_grpc.user_id = user.id
    new_accepted_grpc.insert_product_id_to_po_details(prev_grpc, arr_seq_existed)

    total_after_tax = 0
    total_tax = 0
    sub_total = 0

    params[:purchase_order][:details_purchase_orders_attributes].each do |detail|
      detail[1][:remark]= nil if detail[1].has_key?(:remark)
      detail[1][:total_amount_before_tax] = detail[1][:dispute_price].to_f * detail[1][:dispute_qty]
      if detail[1][:line_tax] != 0 || !detail[1][:line_tax].blank?
        detail[1][:total_amount_after_tax] = (detail[1][:dispute_price].to_f * detail[1][:dispute_qty]) + ((detail[1][:dispute_price].to_f * detail[1][:dispute_qty]) * (detail[1][:line_tax].to_f/100))
      else
        detail[1][:total_amount_after_tax] = detail[1][:total_amount_before_tax]
      end
      total_after_tax += detail[1][:total_amount_after_tax]
      total_tax += (detail[1][:dispute_price].to_f * detail[1][:dispute_qty]) * (detail[1][:line_tax].to_f/100)
      sub_total += detail[1][:dispute_qty] * detail[1][:dispute_price].to_f
    end

    prev_grpc.is_history = true
    prev_grpc.charges_total = total_after_tax
    prev_grpc.tax_amount = total_tax
    prev_grpc.received_total = sub_total
    begin
      ActiveRecord::Base.transaction do
        new_accepted_grpc.save && prev_grpc.save
      end
      send_notifications(new_accepted_grpc)
      return new_accepted_grpc
    rescue =>e
      ActiveRecord::Rollback
    end

    return false
  end

  #this function is used to create accepted grpc
  def self.accept_grpc(prev_grpc,params,user)
    last_key = 0
    arr_seq_existed = []
    params[:purchase_order].merge! prev_grpc.attributes.except(
      "id", "created_at","updated_at","po_remark", "is_history","user_id","supplier_id","warehouse_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed"
    )

    params[:purchase_order][:details_purchase_orders_attributes].each do |k, v|
      det = prev_grpc.details_purchase_orders.where(:seq => v["seq"].to_i).last
      params[:purchase_order][:details_purchase_orders_attributes][k].merge! det.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id", "seq")
      arr_seq_existed << det.seq
      last_key = k.to_i
    end

    unless arr_seq_existed.blank?
      undisputed = prev_grpc.details_purchase_orders.where("seq NOT IN (#{arr_seq_existed.join(',')})").order("seq ASC")
      undisputed.each do |d|
        last_key += 1
        params[:purchase_order][:details_purchase_orders_attributes].merge!({"#{last_key}" => {"remark" => "#{d.remark}", "dispute_price" => d.dispute_price, "is_disputed" => false, "seq" => d.seq}})
        params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id")
        arr_seq_existed << d.seq
      end
    end
    #==========================
    params[:purchase_order].merge! prev_grpc.attributes.except(
      "id", "created_at","updated_at","po_remark", "is_history","user_id","supplier_id","warehouse_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed"
    )
    new_accepted_grpc = PurchaseOrder.new params[:purchase_order]
    new_accepted_grpc.insert_protected_attr(prev_grpc,user)
    new_accepted_grpc.insert_product_id_to_po_details(prev_grpc, arr_seq_existed)

    total_after_tax = 0
    total_tax = 0
    sub_total = 0

    params[:purchase_order][:details_purchase_orders_attributes].each do |detail|
      detail[1][:remark]= nil if detail[1].has_key?(:remark)
      detail[1][:total_amount_before_tax] = detail[1][:dispute_price].to_f * detail[1][:dispute_qty]
      #detail[1][:total_amount_before_tax] = detail[1][:item_price].to_f * detail[1][:received_qty]
      if detail[1][:line_tax] != 0 || !detail[1][:line_tax].blank?
        #detail[1][:total_amount_after_tax] = (detail[1][:item_price].to_f * detail[1][:received_qty]) + ((detail[1][:item_price].to_f * detail[1][:received_qty]) * (detail[1][:line_tax].to_f/100))
        detail[1][:total_amount_after_tax] = (detail[1][:dispute_price].to_f * detail[1][:dispute_qty]) + ((detail[1][:dispute_price].to_f * detail[1][:dispute_qty]) * (detail[1][:line_tax].to_f/100))
      else
        detail[1][:total_amount_after_tax] = detail[1][:total_amount_before_tax]
      end
      current_po = PurchaseOrder.find_by_po_number_and_order_type(prev_grpc.po_number, 'Purchase Order')
      prod_by_po = DetailsPurchaseOrder.find_by_purchase_order_id_and_product_id(current_po.id, detail[1][:product_id])
      total_after_tax += detail[1][:total_amount_after_tax]*(((100-prod_by_po.disc_rate)/100.0) rescue 1)
      #total_tax += (detail[1][:item_price].to_f * detail[1][:received_qty]) * (detail[1][:line_tax].to_f/100)
      total_tax += (detail[1][:dispute_price].to_f * detail[1][:dispute_qty]) * (detail[1][:line_tax].to_f/100)*(((100-prod_by_po.disc_rate)/100.0) rescue 1)
      #sub_total += detail[1][:received_qty] * detail[1][:item_price].to_f
      sub_total += detail[1][:dispute_qty] * detail[1][:dispute_price].to_f*(((100-prod_by_po.disc_rate)/100.0) rescue 1)
    end

    po = PurchaseOrder.find_by_order_type_and_po_number('Purchase Order', prev_grpc.po_number)
    new_invoice = PurchaseOrder.new(params[:purchase_order])
    new_invoice.insert_protected_attr(prev_grpc,user)
    new_invoice.insert_product_id_to_po_details(prev_grpc, arr_seq_existed)
    prev_grpc.is_history = true
    new_invoice.charges_total = total_after_tax
    new_invoice.tax_amount = total_tax
    new_invoice.received_total = sub_total
    prev_grpc.charges_total = total_after_tax
    prev_grpc.tax_amount = total_tax
    prev_grpc.received_total = sub_total
    new_invoice.po_to_?
    begin
      ActiveRecord::Base.transaction do
        if new_accepted_grpc.save && prev_grpc.save && new_invoice.generate_barcode.save
          new_accepted_grpc.accept_grpc if new_accepted_grpc.can_accept_grpc?
          new_invoice.accept_grpc if  new_accepted_grpc.can_accept_grpc?
          send_notifications(new_invoice)
        end
      end
      send_notifications(new_accepted_grpc)
      return new_accepted_grpc
    rescue =>e
      ActiveRecord::Rollback
    end

    return false
  end

  def generate_history
    last_hst = inv_histories.last
    attributes.each{|a|
      InvHistory.create f_name: a[0], old_val: a[1], new_val: a[1], purchase_order_id: id, rev: (last_hst.rev rescue 1)+1
    }
  end

  #this function is used to created dsiputed grpc
  def self.create_dispute_grpc(prev_grpc,params,user)
    arr_seq_existed = []
    last_key = 0
    total_tax, sub_total, total_after_tax = 0,0,0
    params[:purchase_order].merge!(prev_grpc.attributes.except("id", "updated_at", "created_at","po_remark", "is_history", "supplier_id", "user_id","warehouse_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed","charges_total","tax_amount","received_total"))

    params[:purchase_order][:details_purchase_orders_attributes].each do |k, v|
      det = prev_grpc.details_purchase_orders.where(:seq => v["seq"].to_i).last
      params[:purchase_order][:details_purchase_orders_attributes][k].merge! det.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id","dispute_price","total_amount_before_tax","seq")
      params[:purchase_order][:details_purchase_orders_attributes][k]["total_amount_before_tax"] = params[:purchase_order][:details_purchase_orders_attributes][k]["dispute_qty"].to_f * params[:purchase_order][:details_purchase_orders_attributes][k]["dispute_price"].to_f

      total_after_tax += params[:purchase_order][:details_purchase_orders_attributes][k]["total_amount_before_tax"].to_f
      total_tax += (params[:purchase_order][:details_purchase_orders_attributes][k]["total_amount_before_tax"]) * (params[:purchase_order][:details_purchase_orders_attributes][k]["line_tax"].to_f/100)
      sub_total += params[:purchase_order][:details_purchase_orders_attributes][k]["total_amount_before_tax"].to_f

      arr_seq_existed << det.seq
      last_key = k.to_i
    end

    undisputed = prev_grpc.details_purchase_orders.where("seq NOT IN (#{arr_seq_existed.join(',')})").order("seq ASC")
    undisputed.each do |d|
      last_key += 1
      params[:purchase_order][:details_purchase_orders_attributes].merge!({"#{last_key}" => {"remark" => "#{d.remark}"}})
      params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id")

      params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["total_amount_before_tax"] = params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["dispute_qty"].to_f * params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["dispute_price"].to_f

      total_after_tax += params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["total_amount_before_tax"].to_f
      total_tax += (params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["total_amount_before_tax"]) * (params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["line_tax"].to_f/100)
      sub_total += params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["total_amount_before_tax"].to_f

      arr_seq_existed << d.seq
    end

    #prev_grpc.details_purchase_orders.order("seq ASC").each_with_index do |d, index|
    #  params[:purchase_order][:details_purchase_orders_attributes][index.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id","dispute_price","total_amount_before_tax")
    #  params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["total_amount_before_tax"] = params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["dispute_qty"].to_f * params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["dispute_price"].to_f

    #  total_after_tax += params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["total_amount_before_tax"].to_f
    #  total_tax += (params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["total_amount_before_tax"]) * (params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["line_tax"].to_f/100)
    #  sub_total += params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["total_amount_before_tax"].to_f
    #end

    new_dispute_grpc = PurchaseOrder.new(params[:purchase_order])
    new_dispute_grpc.insert_protected_attr(prev_grpc,user)
    new_dispute_grpc.insert_product_id_to_po_details(prev_grpc, arr_seq_existed)
    new_dispute_grpc.charges_total = total_after_tax
    new_dispute_grpc.tax_amount = total_tax
    new_dispute_grpc.received_total = sub_total
    prev_grpc.is_history = true
    begin
      ActiveRecord::Base.transaction do
        if new_dispute_grpc.save && prev_grpc.save
          new_dispute_grpc.raise_dispute_grpc if new_dispute_grpc.can_raise_dispute_grpc?
        end
      end
      send_notifications(new_dispute_grpc)
      return new_dispute_grpc
    rescue => e
      ActiveRecord::Rollback
      return false
    end
  end

  def last_update_by_other_user_current_by_current_user? current_user
    (user.roles.map(&:parent).include?(Role.find_by_name('customer')) && current_user.roles.map(&:parent).include?(Role.find_by_name('supplier')) || user.roles.map(&:parent).include?(Role.find_by_name('supplier')) && current_user.roles.map(&:parent).include?(Role.find_by_name('customer'))) rescue current_user.roles.map(&:parent).include?(Role.find_by_name('supplier'))
  end

  #this function is used to create revised grpc
  def self.create_revised_grpc(prev_grpc,params,user)
    last_key = 0
    arr_seq_existed = []

    revision_to = self.where(:grn_number => "#{prev_grpc.grpc_number}").with_grpc_state(:rev).count + 1
    disputed_grpc = prev_grpc
    total_tax, sub_total, total_after_tax = 0,0,0
    params[:purchase_order].merge!(disputed_grpc.attributes.except("id", "updated_at", "created_at", "po_remark", "is_history", "supplier_id","warehouse_id","user_id","state","inv_state", "grn_state", "asn_state", "is_history", "is_published","grpc_state","is_completed","charges_total","tax_amount","received_total"))

    params[:purchase_order][:details_purchase_orders_attributes].each do |k, v|
      det = disputed_grpc.details_purchase_orders.where(:seq => v["seq"].to_i).last
      params[:purchase_order][:details_purchase_orders_attributes][k].merge! det.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id")
      params[:purchase_order][:details_purchase_orders_attributes][k]["total_amount_before_tax"] = params[:purchase_order][:details_purchase_orders_attributes][k]["dispute_qty"].to_f * params[:purchase_order][:details_purchase_orders_attributes][k]["dispute_price"].to_f

      total_after_tax += params[:purchase_order][:details_purchase_orders_attributes][k]["total_amount_before_tax"].to_f
      total_tax += (params[:purchase_order][:details_purchase_orders_attributes][k]["total_amount_before_tax"]) * (params[:purchase_order][:details_purchase_orders_attributes][k]["line_tax"].to_f/100)
      sub_total += params[:purchase_order][:details_purchase_orders_attributes][k]["total_amount_before_tax"].to_f

      arr_seq_existed << det.seq
      last_key = k.to_i
    end

    undisputed = disputed_grpc.details_purchase_orders.where("seq NOT IN (#{arr_seq_existed.join(',')})").order("seq ASC")
    undisputed.each do |d|
      last_key += 1
      params[:purchase_order][:details_purchase_orders_attributes].merge!({"#{last_key}" => {"remark" => "#{d.remark}"}})
      params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id")
      params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["total_amount_before_tax"] = params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["dispute_qty"].to_f * params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["dispute_price"].to_f

      total_after_tax += params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["total_amount_before_tax"].to_f
      total_tax += (params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["total_amount_before_tax"]) * (params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["line_tax"].to_f/100)
      sub_total += params[:purchase_order][:details_purchase_orders_attributes][last_key.to_s]["total_amount_before_tax"].to_f

      arr_seq_existed << d.seq
    end

    #disputed_grpc.details_purchase_orders.order("seq asc").each_with_index do |d, index|
    #  params[:purchase_order][:details_purchase_orders_attributes][index.to_s].merge! d.attributes.except("id","updated_at","created_at","purchase_order_id", "remark","product_id","dispute_price","total_amount_before_tax")
    #  params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["total_amount_before_tax"] = params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["dispute_qty"].to_f * params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["dispute_price"].to_f

    #  total_after_tax += params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["total_amount_before_tax"].to_f
    #  total_tax += (params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["total_amount_before_tax"]) * (params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["line_tax"].to_f/100)
    #  sub_total += params[:purchase_order][:details_purchase_orders_attributes][index.to_s]["total_amount_before_tax"].to_f
    #end
    new_revised_grpc = PurchaseOrder.new(params[:purchase_order])
    new_revised_grpc.insert_protected_attr(disputed_grpc,user)
    new_revised_grpc.insert_product_id_to_po_details(disputed_grpc, arr_seq_existed)
    new_revised_grpc.revision_to = revision_to
    new_revised_grpc.charges_total = total_after_tax
    new_revised_grpc.tax_amount = total_tax
    new_revised_grpc.received_total = sub_total
    disputed_grpc.is_history= true
    begin
      ActiveRecord::Base.transaction do
        if new_revised_grpc.save && disputed_grpc.save
          new_revised_grpc.revise_grpc if new_revised_grpc.can_revise_grpc?
        end
      end
      send_notifications(new_revised_grpc)
      return new_revised_grpc
    rescue => e
      ActiveRecord::Rollback
    end

    return false
  end

  #this function is used to determine status for grn or grpc
  def self.grn_status(params)
    case params
      when "unread"
        t=1
      when "read"
        t=2
      when "dispute"
        t=3
      when "rev"
        t=4
      when "accepted"
        t=5
      end
      return t
  end
  def self.asn_status(params)
    case params
      when "unread"
        t=1
      when "read"
        t=2
      return t
    end
  end

  def self.inv_status(params)
    case params
     when "draft"
       t = 0
     when "published"
       t=1
    end
  end

  def respond_to_inv(params, user)
    self.po_remark = params[:purchase_order][:po_remark]
    self.user_id = user.id
    if self.po_remark.blank?
      ret = self.get_push_cre_trans_to_api
      case ret
      when true
        self.receive_inv
        return true
      when 2
        return 2
      else
        return false
      end
    else
      self.user_id = user.id
      if self.receive_incomplete_inv
        return true
      end
    end

    return false
  end

  def push_invoice_to_api
    flag = false
    self.user_id = user.id
    if !self.is_completed_invoice_to_api
      ret = self.get_push_cre_trans_to_api(true)
      case ret
      when true
        self.details_purchase_orders.each do |det|
          if !det.is_completed_invoice_to_api
            ret = self.get_push_po_line(det)
            case ret
            when true
              #return true
            when 2
              return 2
            else
              return false
            end
          end
        end
        return true
      when 2
        return 2
      else
        return false
      end
    end

    return false
  end

  def get_push_cre_trans_to_api(status=nil)
    #push invoice untuk b2b-temp-cre-trans
      total_gap = self.tax_gap.to_i + self.dpp_gap.to_i
    begin
      self.invoice_due_date = self.invoice_date = Time.now
      inv_date = (self.invoice_date.to_date.strftime("%Y-%m-%d") rescue '') #diambil dari tanggal ketika receive menjadi completed
      print_invoice_date = (self.print_invoice_date.to_date.strftime("%Y-%m-%d") rescue '')
      reported_date = (self.tax_invoice_date.to_date.strftime("%Y-%m-%d") rescue '')

      values = "{" +
          "\"b2b_tr_user_only_num_1\": #{self.tax_gap.to_i}," +
          "\"b2b_tr_user_only_num_2\": #{self.dpp_gap.to_i}," +
          (((self.tax_gap + self.dpp_gap > 1000) rescue false) ? "\"b2b_tr_user_only_num_3\": #{total_gap}," : "") +
          (((self.tax_gap + self.dpp_gap > 1000) rescue false) ? "\"b2b_cr_tr_spare_flag\": \"1\"," : "") +# total gap > 1000 tandai flag "1" di user_only_alpha4_2
          "\"b2b_cre_accountcode\": \"#{self.supplier.code}\"," +
          "\"b2b_cr_tr_pay_by_date\": \"#{inv_date}\"," +
          "\"b2b_cr_tr_date\": \"#{print_invoice_date}\"," +
          "\"b2b_cr_tr_reference\": \"#{self.invoice_number}\"," +
          "\"b2b_cr_tr_po_order_no\": #{self.po_number.to_i}," +
          "\"b2b_backorder_flag\": \"#{self.backorder_flag}\"," +
          "\"b2b_cr_tr_details\": \"#{self.user.username}\"," +
          "\"b2b_cr_tr_amount\": #{self.charges_total.to_f}," +
          "\"b2b_cr_tr_invoice_date\": \"#{inv_date}\"," +
          "\"b2b_cr_tr_tax_amount\": #{self.tax_amount.to_f}," +
          "\"b2b_cr_tr_reported_date\": \"#{reported_date}\"," +
          "\"b2b_cr_tr_date_stamp\": \"#{Time.now.strftime("%Y-%m-%d")}\"," +
          "\"b2b_cr_tr_time_stamp\": \"#{Time.now.strftime("%H:%M:%S")}\"," +
          "\"b2b_cr_tr_other_side\": \"#{self.tax_invoice_number}\"," +
          "\"b2b_amt_before_tax\": \"#{self.received_total.to_f}\"," +
          "\"b2b_inv_due_date\": \"#{self.payment_invoice_due_date.strftime("%Y-%m-%d")}\"," +
          "\"b2b_retention_approved\": \"1\"" +
        "}"

      req_cre_trans = OffsetApi.get_push_invoice("b2btempcretrans/create", values)
    rescue => e
      return 2 #mengebalikan status untuk service atau pun server mati pada API
    end

    if req_cre_trans.is_a?(Net::HTTPSuccess)
      #jika sukses akan update is_completed_invoice_to_api di purchase_orders b2b = TRUE
      self.update_attributes(:is_completed_invoice_to_api => true)
      self.get_push_po_line if status.blank?
      return true
    end

    return OffsetApi.eval_net_http(req_cre_trans)
  end

  def get_push_po_line(det=nil)
    #push invoice untuk b2b-temp-po-line
    unless det
      self.details_purchase_orders.order("seq ASC").each do |det|
        values = "{" +
            "\"b2b_po_order_no\": #{self.po_number.to_i}," +
            "\"b2b_backorder_flag\": \"#{det.backorder_flag}\"," +
            "\"b2b_po_l_seq\": #{det.seq.to_i}," +
            "\"b2b_stock_code\": \"#{det.try(:product).try(:code)}\"," +
            "\"b2b_po_order_qty\": #{det.order_qty.to_f}," +
            "\"b2b_po_received_qty\": #{det.dispute_qty.to_f}," +
            "\"b2b_po_item_price\": #{det.dispute_price.to_f}" +
        "}"

        begin
          req_po_line = OffsetApi.get_push_invoice("b2btemppoline/create", values)
          if req_po_line.is_a?(Net::HTTPSuccess)
            #jika sukses akan update is_completed_invoice_to_api di details_purchase_orders b2b = TRUE
            det.update_attributes(:is_completed_invoice_to_api => true)
          end
          #return false
        rescue => e
          return 2 #mengebalikan status untuk service atau pun server mati pada API
        end
        return OffsetApi.eval_net_http(req_po_line) unless req_po_line.is_a?(Net::HTTPSuccess)
      end
    else
      values = "{" +
          "\"b2b_po_order_no\": #{det.purchase_order.po_number.to_i}," +
          "\"b2b_backorder_flag\": \"#{det.backorder_flag}\"," +
          "\"b2b_po_l_seq\": #{det.seq.to_i}," +
          "\"b2b_stock_code\": \"#{det.try(:product).try(:code)}\"," +
          "\"b2b_po_order_qty\": #{det.order_qty.to_f}," +
          "\"b2b_po_received_qty\": #{det.dispute_qty.to_f}," +
          "\"b2b_po_item_price\": #{det.dispute_price.to_f}" +
      "}"

      begin
        req_po_line = OffsetApi.get_push_invoice("b2btemppoline/create", values)
        if req_po_line.is_a?(Net::HTTPSuccess)
          #jika sukses akan update is_completed_invoice_to_api di details_purchase_orders b2b = TRUE
          det.update_attributes(:is_completed_invoice_to_api => true)
        end
        #return false
      rescue => e
        return 2 #mengebalikan status untuk service atau pun server mati pada API
      end
      return OffsetApi.eval_net_http(req_po_line) unless req_po_line.is_a?(Net::HTTPSuccess)
    end
    return false
  end

  #this function is used to determine status for po
  def self.po_status(params)
    case params
      when "new"
        t=0
      when "open"
        t=1
      when "on time"
        t=2
      when "on time but less 100"
        t=3
      when "late"
        t=4
      when "late but less 100"
        t=5
      when "expired"
        t=6
      end
      return t
  end

  # this function is used to check whether po asn has draft or not
  def self.draft_asn_existed?(po_number)
    asn_draft=PurchaseOrder.find(:all, :conditions => ["po_number like ? and order_type ilike ? and is_published = false","%#{po_number}%", "%#{ASN}%"]).last
    return asn_draft
  end

  # this function is used to find parent po for creating asn
  def self.get_po_parent(po_number)
    po_parent = PurchaseOrder.where(:po_number=>"#{po_number}", :order_type=>"#{PO}", :is_published => false).last
    return po_parent
  end

  def grpc_can_be_revised? current_user
    return false if current_user.warehouse.blank?
    grpc_dispute_setting = DisputeSetting.find_by_transaction_type('GRPC')
    current_level = UserLevelDispute.where("user_id=#{current_user.id} AND dispute_setting_id=#{grpc_dispute_setting.id}").last
    return true if PurchaseOrder.where("user_id=#{current_user.id} AND grpc_number='#{grpc_number}'").count < grpc_dispute_setting.max_round && UserLevelDispute.where("dispute_setting_id=#{grpc_dispute_setting.id} AND level > #{current_level.level}").present?
    po_count = PurchaseOrder.where("user_id=#{current_user.id} AND grpc_number='#{grpc_number}' AND grpc_state=4").count
    if GeneralSetting.where(:desc => "Last GRPC Approval").first.value == "Customer"
      current_user.warehouse.present? && po_count < DisputeSetting.find_by_transaction_type('GRPC').max_round-1
    else
      current_user.warehouse.present? && po_count < DisputeSetting.find_by_transaction_type('GRPC').max_round
    end
  end

  def can_be_revised? current_user
    if GeneralSetting.where(:desc => "Last GRN Approval").first.value == "Customer"
      current_user.warehouse.present? && PurchaseOrder.where("user_id=#{current_user.id} AND grn_number='#{grn_number}'").count < DisputeSetting.find_by_transaction_type('GRN').max_round-1
    else
      current_user.warehouse.present? && PurchaseOrder.where("user_id=#{current_user.id} AND grn_number='#{grn_number}'").count < DisputeSetting.find_by_transaction_type('GRN').max_round
    end
  end

 #this function is used to store the po in db but yet published
  def asn_saved?
    self.po_to_?
    self.is_published = false
    if self.save
      return true
    else
      return false
    end
  end

  #this function is used to published the asn and publish its parent po
  def published?(params,user)
    self.user_id = user.id
    self.is_published = true
    self.po_to_?
    parent = PurchaseOrder.get_po_parent(self.po_number)
    if self.new_record?
      begin
        ActiveRecord::Base.transaction do
          if self.save
            self.open_po if self.can_open_po?
            parent.is_published = true
            parent.user_id = user.id
            parent.open_po if parent.can_open_po?
          end
        end
        PurchaseOrder.send_notifications(self)
        return true
      rescue => e
        ActiveRecord::Rollback
      end
    else
      begin
        ActiveRecord::Base.transaction do
          if self.update_attributes(params)
            self.open_po if self.can_open_po?
            parent.open_po if parent.can_open_po?
            parent.is_published = true
            parent.user_id = user.id
            parent.save
          end
        end
        PurchaseOrder.send_notifications(self)
        return true
      rescue => e
        ActiveRecord::Rollback
      end
    end

    return false
  end

  #this function is used to change the order_type of po to asn, grn,or something else
  def po_to_?
    case self.order_type
    when "#{PO}"
      self.order_type = "#{ASN}"
      when "#{ASN}"
        self.order_type = "#{ASN}"
        when "#{GRN}"
          self.order_type = "#{GRPC}"
          when "#{GRPC}"
            self.order_type = "#{INV}"
    end
  end

  #this function is used to count service level, what is service level? see tor!
  def count_service_level(parent)
    supplier = Supplier.find(self.supplier_id)
    sl = supplier.service_level
    en = supplier.extra_notes.first
    details = self.details_purchase_orders

    unless en.blank?
      en = ExtraNote.find(:all, :conditions=>["en_type ilike ?","%df%"]).first
    end
    if sl.nil?
      default_sl= ServiceLevel.find_by_sl_code("Default")
      if default_sl.nil?
        sl = {:sl_qty=> 30, :sl_line=>30, :sl_time=>40}
      else
        sl = default_sl
      end
    # sum of supplier's service level
      now = Date.today
      time = 0
      if self.received_date > self.due_date
        days = en[:text].split(/[[:alpha:]]/) rescue []
        exp = 0
        days.each do |day|
          exp = day.to_i if day.to_i != 0
        end
        expired_date = self.due_date + exp
        diff = self.received_date - self.due_date
        time = (exp-diff)/exp rescue 0
      end
      received_line_total = details.count
      ordered_qty_total = parent.details_purchase_orders.count
      ordered_total = 0
      received_total = 0
      details.each do |detail|
        ordered_total =+ detail.order_qty
        received_total =+ detail.received_qty
      end

      qty =(ordered_total - received_total)/ ordered_total
      line =(ordered_qty_total - received_line_total) /ordered_qty_total
      p_line = (1 - line) * sl[:sl_line]
      p_qty = (1 - qty) * sl[:sl_qty]
      p_time = (1- time) * sl[:sl_time]
      total_sl = p_line + p_qty  + p_time

      supplier[:sl_line_total] = p_line
      supplier[:sl_order_total] = p_qty
      supplier[:sl_time_total] = p_time
      supplier[:service_level_total] = total_sl
      new_history_of_service_level = ServiceLevelHistory.new(:po_type=>"#{PO}",:total_sl=>total_sl)
      new_history_of_service_level.supplier_id = self.supplier_id
      new_history_of_service_level.purchase_order_id = self.id
      if supplier.save && new_history_of_service_level.save
        return true
      else
        return false
      end
    end
  end

  #this function is used to count records of grn revised.
  def count_rev_of(type)
    if type == "#{GRN}"
      count = PurchaseOrder.with_grn_state(:rev).where(:order_type => "#{type}", :po_number => self.po_number).count
    elsif type == "#{GRPC}"
      count = PurchaseOrder.with_grpc_state(:rev).where(:order_type => "#{type}", :po_number => self.po_number).count
    end
    return count
  end

  def self.send_grn
    limit = LevelLimit.select('limit_date, warehouse_id, email_address_1, email_address_2, email_address_3, email_address_4, email_address_5').where("level_type = ?", "#{GRN}")
    limit.each do |l|
      po = PurchaseOrder.select('DISTINCT (po_number) po_number, id, warehouse_id, created_at').where("order_type = ? AND grn_state != 5", "#{GRN}").order("id ASC")
      po.each do |p|
        if l.warehouse_id == p.warehouse_id
          date = (Date.today - p.created_at.to_date).to_i
          email = EmailLevelLimit.find_by_warehouse_id_and_email_type(l.warehouse_id, 'grn')
          case date
          when l.limit_date
            unless l.email_address_1.nil?
              begin
                UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grn(l.email_address_1, p, email)
              rescue => e
                OffsetApi.write_to_email_log(522,"Notifications GRN")
              end
            else
              OffsetApi.write_to_email_log(204, "email address lvl1")
            end
          when l.limit_date * 2
            unless l.email_address_2.nil?
              begin
                UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grn(l.email_address_2, p, email)
              rescue => e
                OffsetApi.write_to_email_log(522,"Notifications GRN")
              end
            else
              OffsetApi.write_to_email_log(204, "email address lvl1")
            end
          when l.limit_date * 3
            unless l.email_address_3.nil?
              begin
                UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grn(l.email_address_3, p, email)
              rescue => e
                OffsetApi.write_to_email_log(522,"Notifications GRN")
              end
            else
              OffsetApi.write_to_email_log(204, "email address lvl3")
            end
          when l.limit_date * 4
            unless l.email_address_4.nil?
              begin
                UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grn(l.email_address_4, p, email)
              rescue => e
                OffsetApi.write_to_email_log(522,"Notifications")
              end
            else
              OffsetApi.write_to_email_log(204, "email address lvl4")
            end
          when l.limit_date * 5
            unless l.email_address_3.nil?
              begin
                UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grn(l.email_address_5, p, email)
              rescue => e
                OffsetApi.write_to_email_log(522,"Notifications")
              end
            else
              OffsetApi.write_to_email_log(204, "email address lvl5")
            end
          end
        end
      end
    end
  end

  def self.send_grpc
    limit = LevelLimit.select('limit_date, warehouse_id, email_address_1, email_address_2, email_address_3').where("level_type = ?", "#{GRPC}")
    limit.each do |l|
      po = PurchaseOrder.select('DISTINCT (po_number) po_number, id, warehouse_id, created_at').where("order_type = ? AND grpc_state != 5", "#{GRPC}").order("id ASC")
      po.each do |p|
        if l.warehouse_id == p.warehouse_id
          date = (Date.today - p.created_at.to_date).to_i
          email = EmailLevelLimit.find_by_warehouse_id_and_email_type(l.warehouse_id, 'grpc')
          case date
            when l.limit_date
              unless l.email_address_1.nil?
                begin
                  UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grpc(l.email_address_1, p, email)
                rescue => e
                  OffsetApi.write_to_email_log(522,"Notifications GRPC")
                end
              else
                OffsetApi.write_to_email_log(204, "email address lvl1")
              end
            when l.limit_date * 2
              unless l.email_address_2.nil?
                begin
                  UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grpc(l.email_address_2, p, email)
                rescue => e
                  OffsetApi.write_to_email_log(522,"Notifications GRPC")
                end
              else
                OffsetApi.write_to_email_log(204, "email address lvl2")
              end
            when l.limit_date * 3
              unless l.email_address_2.nil?
                begin
                  UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grpc(l.email_address_3, p, email)
                rescue => e
                  OffsetApi.write_to_email_log(522,"Notifications GRPC")
                end
              else
                OffsetApi.write_to_email_log(204, "email address lvl3")
              end
            end
        end
      end
    end
  end

  def self.send_email_notification_when_synch(obj)
    state,path,url = '','',''
    if obj.class.name == "PurchaseOrder"
      case obj.order_type
        when "#{PO}"
          state = obj.state_name.to_s
          users = obj.supplier.users.where(:is_received_po => true, is_activated: true)+obj.warehouse.users.where(:is_received_po => true, is_activated: true)
          path = 'purchase_orders'
        when "#{GRN}"
          state = obj.grn_state_name.to_s
          users = obj.supplier.users.where(:is_received_grn => true, is_activated: true)+obj.warehouse.users.where(:is_received_grn => true, is_activated: true)
          path = 'goods_receive_notes'
      end
      url = "order_to_payments/#{path}/#{obj.id}"
    elsif obj.class.name == "DebitNote"
      state = obj.state_name.to_s
      users = obj.warehouse.users.where(:is_received_dn => true, is_activated: true)
      path = 'debit_notes'
      url = "order_to_payments/#{path}/#{obj.id}"
    elsif obj.class.name == "ReturnedProcess"
      state = obj.state_name.to_s
      users = obj.purchase_order.supplier.users.where(is_activated: true)
      path = 'returned_processes'
      url = "#{path}/#{obj.id}"
    end
    unless users.nil?
      begin
        if obj.order_type == "#{PO}"
          UserMailer.mailer_notification_synchronize(obj.po_number, users.split(","), obj.state_name, obj.order_type, url).deliver
        elsif obj.order_type == "#{GRN}"
          UserMailer.mailer_notification_synchronize(obj.grn_number, users.split(","), obj.grn_state_name, obj.order_type, url).deliver
        elsif obj.order_type == "#{GRTN}"
          UserMailer.mailer_notification_synchronize(obj.rp_number, users.split(","), obj.state_name, GRTN, url).deliver
        elsif obj.order_type == "#{DN}"
          UserMailer.mailer_notification_synchronize(obj.order_number, users.split(","), obj.state_name, DN, url).deliver
        end
      rescue => e
        OffsetApi.write_to_email_log(522,"Notifications #{obj.order_type}") rescue ''
      end
    else
      OffsetApi.write_to_email_log(204,"Email or User #{obj.order_type}  not found") rescue ''
    end
  end

  def self.send_notifications(obj)
    state = ''
    if obj.class.name == "PurchaseOrder"
      case obj.order_type
        when "#{PO}"
          state = obj.state_name.to_s
          users = obj.warehouse.users.where(:is_received_po => true, is_activated: true)
          path = 'purchase_orders'
        when "#{GRN}"
          state = obj.grn_state_name.to_s
          users = obj.warehouse.users.where(:is_received_grn => true, is_activated: true)+obj.supplier.users.where(:is_received_grn => true, is_activated: true)
          path = 'goods_receive_notes'
        when "#{GRPC}"
          state = obj.grpc_state_name.to_s
          users = obj.warehouse.users.where(:is_received_grpc => true, is_activated: true)+obj.supplier.users.where(:is_received_grpc => true, is_activated: true)
          path = 'goods_receive_price_confirmations'
        when "#{ASN}"
          state = obj.asn_state_name.to_s
          users = obj.warehouse.users.where(:is_received_grpc => true, is_activated: true)+obj.supplier.users.where(:is_received_grpc => true, is_activated: true)
          path = 'advance_shipment_confirmations'
        when "#{INV}"
          state = obj.inv_state_name.to_s
          if state == 'nil'
            state = 'new'
          end
          users = obj.warehouse.users.where(:is_received_invoice => true, is_activated: true)+obj.supplier.users.where(:is_received_invoice => true, is_activated: true)
          path = 'invoices'
        end
      #Send email notification
      email = EmailNotification.find_by_type_po_and_state(obj.order_type, state)
      url = "order_to_payments/#{path}/#{obj.id}"
      unless email.nil? || users.nil?
        begin
          UserMailer.mailer_notification(obj.po_number, state, users.split(","), email, obj.order_type, url).deliver rescue ''
          #UserMailer.mailer_notification(obj.po_number, state, users.split(","), email, obj.order_type).deliver
        rescue => e
          OffsetApi.write_to_email_log(522,"Notifications PurchaseOrder")
        end
      else
        OffsetApi.write_to_email_log(204,"Email or User #{obj.order_type}  not found")
      end
    elsif obj.class.name == "EarlyPaymentRequest"
      state = obj.state_name.to_s
      users = obj.purchase_order.warehouse.users.where(:is_received_early_payment_request => true, is_activated: true)
      url = "order_to_payments/invoices/#{obj.purchase_order_id}"
      email = EmailNotification.find_by_type_po_and_state("Early Payment Request", state)
      unless email.nil? || users.nil?
        begin
            po_number = PurchaseOrder.find(po_number).po_number
            UserMailer.delay(run_at: DELAY_NOTIF).mailer_notification(po_number, state, users.split(","), email, 'Early payment request', url)
            #UserMailer.mailer_notification(obj.purchase_order_id, state, users.split(","), email, 'Early payment request').deliver
        rescue => e
            OffsetApi.write_to_email_log(522,"Early Payment Request")
        end
      else
        OffsetApi.write_to_email_log(204,"Email or User Early Payment request not found")
      end
    #debite note
    elsif obj.class.name == "DebitNote"
      state = obj.state_name.to_s
      users = obj.warehouse.users.where(:is_received_debit_note => true, is_activated: true)+obj.supplier.users.where(:is_received_debit_note => true, is_activated: true)
      url = "order_to_payments/debit_notes/#{obj.id}"
      email = EmailNotification.find_by_type_po_and_state("DebitNote", state)
      unless email.nil? || users.nil?
        begin
            UserMailer.delay(run_at: DELAY_NOTIF).mailer_notification(obj.order_number, state, users.split(","), email, 'DebitNote', url).deliver
            #UserMailer.mailer_notification(obj.order_number, state, users.split(","), email, 'DebitNote').deliver
        rescue => e
            OffsetApi.write_to_email_log(522,"Notifications Debit Note")
        end
      else
        OffsetApi.write_to_email_log(204,"Email or User DebitNote not found")
      end
    #payment Voucher
    elsif obj.class.name == "PaymentVoucher"
      state = obj.is_approved_name.to_s
      users = obj.warehouse.users.where(:is_received_payment_voucher => true, is_activated: true)+obj.supplier.users.where(:is_received_payment_voucher => true, is_activated: true)
      email = EmailNotification.find_by_type_po_and_state('Payment Voucher', state)
      url = "payment_vouchers/#{obj.id}"

      unless email.nil? || users.nil?
        begin
          UserMailer.delay(run_at: DELAY_NOTIF).mailer_notification(obj.voucher, state, users.split(","), email, 'Payment voucher', url)
          #UserMailer.mailer_notification(obj.voucher, state, users.split(","), email, 'Payment voucher').deliver
        rescue => e
          OffsetApi.write_to_email_log(522,"Notifications PurchaseOrder")
        end
      else
        OffsetApi.write_to_email_log(204,"Email or User Payment Voucher not found")
      end

    elsif obj.class.name == "Payment"
      state = obj.state_name.to_s
      users = obj.warehouse.users.where(:is_received_payment_process => true, is_activated: true)
      url = "payments/#{obj.id}"
      email = EmailNotification.find_by_type_po_and_state('Payment Process', state)
      begin
        UserMailer.delay(run_at: DELAY_NOTIF).mailer_notification(obj.no, state, users.split(","), email, 'Payment Process', url)
        #UserMailer.mailer_notification(obj.no, state, users.split(","), email, 'Payment Process').deliver
      rescue => e
        OffsetApi.write_to_email_log(522,"Notifications PurchaseOrder")
      end
    elsif obj.class.name == "ReturnedProcess"
      state = obj.state_name.to_s
      users = obj.purchase_order.warehouse.users.where(:is_received_grtn => true, is_activated: true)
      #send notifications GRN
      email = EmailNotification.find_by_type_po_and_state("#{GRTN}", state)
      url = "returned_processes/#{obj.id}"
      unless email.nil?
        begin
          UserMailer.delay(run_at: DELAY_NOTIF).mailer_notification(obj.rp_number, state, users.split(","), email, 'Return process', url)
          #UserMailer.mailer_notification(obj.rp_number, state, users.split(","), email, 'Return process').deliver
        rescue => e
          OffsetApi.write_to_email_log(522,"Notifications ReturnedProcess")
        end
      else
        OffsetApi.write_to_email_log(204,"Email Return process #{state} not found")
      end
    end
  end

  #this function is used to count all po status for transaction dashboard status for today
  def self.count_po_statuses_today(type,current_user)
    if current_user.has_role?(:superadmin)
      po = PurchaseOrder.select("DISTINCT ON (po_number) po_number, purchase_orders.id,state, asn_state, grn_state,grpc_state, inv_state, purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").find(:all, :conditions=>["order_type = ? and Date(purchase_orders.updated_at)=Date(?)", "#{type}", Time.now])
      #po = PurchaseOrder.select("DISTINCT ON (po_number) po_number, purchase_orders.id,state, asn_state, grn_state,grpc_state, inv_state, purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").find(:all, :conditions=>["order_type = ?", "#{type}"])
    elsif  current_user.supplier.present?
      if current_user.supplier.group.present?  && current_user.try(:roles).try(:first).try(:group_flag)
        po = PurchaseOrder.joins(:supplier).select("DISTINCT ON (po_number) po_number, purchase_orders.id,state, asn_state, grn_state,grpc_state, inv_state, purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").where("suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and Date(purchase_orders.updated_at)=Date(?)", "#{type}", Time.now)
      else
        po = current_user.supplier.purchase_orders.select("DISTINCT ON (po_number) po_number, purchase_orders.id,state, asn_state, grn_state,grpc_state, inv_state,  purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").find(:all, :conditions=>["order_type = ? and Date(purchase_orders.updated_at)=Date(?)", "#{type}", Time.now])
      end
    else
      unless current_user.warehouse.blank?
        if current_user.warehouse.group.present? && current_user.try(:roles).try(:first).try(:group_flag)
          po = PurchaseOrder.joins(:warehouse).select("DISTINCT ON (po_number) po_number, purchase_orders.id,state,asn_state, grn_state,grpc_state, inv_state,  purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").find(:all, :conditions=>["warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and Date(purchase_orders.updated_at)=Date(?)", "#{type}", Time.now])
        else
          po = current_user.warehouse.purchase_orders.select("DISTINCT ON (po_number) po_number, purchase_orders.id,asn_state, state,grn_state,grpc_state, inv_state,  purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").find(:all, :conditions=>["order_type = ? and Date(purchase_orders.updated_at)=Date(?)", "#{type}", Time.now]) #, Time.now -- and Date(purchase_orders.updated_at)=Date(?)
        end
      end
    end

      case type
      when "#{PO}"
        count = {:new=>0, :open=>0, :on_time=>0, :on_time_less=>0, :late=>0, :late_less=>0, :expired=>0, :for=>"#{PO}"}
        unless po.blank?
        po.each do |p|
          case p.state
          when 0
            count[:new] +=1
          when 1
            count[:open] +=1
          when 2
            count[:on_time] +=1
          when 3
            count[:on_time_less] +=1
          when 4
            count[:late] +=1
          when 5
            count[:late_less] +=1
          when 6
            count[:expired] +=1
          end
        end
      end
    when "#{ASN}"
      count = {:new=>0, :read=>0, :for=>"#{ASN}"}
      unless po.blank?
        po.each do |p|
          case p.asn_state_name.to_s
          when "new"
            count[:new] +=1
          when "read"
            count[:read] +=1
          end
        end
      end
      when "#{INV}"
        count = {:new=>0, :printed=>0, :rejected=>0, :incomplete=>0, :completed=>0, :for=>"#{INV}"}
        unless po.blank?
          po.each do |p|
            case p.inv_state_name.to_s
              when "nil", "new"
                count[:new] +=1
              when "printed"
                count[:printed] +=1
              when "rejected"
                count[:rejected] +=1
              when "incomplete"
                count[:incomplete] +=1
              when "completed"
                count[:completed] +=1
            end
          end
        end

      when "#{GRN}"
        count = {:new=>0, :read=>0,:dispute=>0,:rev=>0, :pending=>0, :accepted=>0, :for=>"#{GRN}"}
        unless po.blank?
          po.each do |p|
            case p.grn_state_name.to_s
            when "new"
              count[:new] +=1
            when "read"
              count[:read] +=1
            when "dispute"
              count[:dispute] +=1
            when "rev"
              count[:rev]  +=1
            when "pending"
              count[:pending] +=1
            when "accepted"
              count[:accepted] +=1
            end
          end
        end
      end
      return count
  end

  def self.count_po_statuses(type,current_user)
    if current_user.has_role?(:superadmin)
      po = PurchaseOrder.select("DISTINCT ON (po_number) po_number, purchase_orders.id,state, asn_state, grn_state,grpc_state, inv_state, purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").find(:all, :conditions=>["order_type = ?", "#{type}"])
      #po = PurchaseOrder.select("DISTINCT ON (po_number) po_number, purchase_orders.id,state, asn_state, grn_state,grpc_state, inv_state, purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").find(:all, :conditions=>["order_type = ?", "#{type}"])
    elsif  current_user.supplier.present?
      if current_user.supplier.group.present?  && current_user.try(:roles).try(:first).try(:group_flag)
        po = PurchaseOrder.joins(:supplier).select("DISTINCT ON (po_number) po_number, purchase_orders.id,state, asn_state, grn_state,grpc_state, inv_state, purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").where("suppliers.group_id = #{current_user.supplier.group.id} and order_type = ?", "#{type}")
      else
        po = current_user.supplier.purchase_orders.select("DISTINCT ON (po_number) po_number, purchase_orders.id,state, asn_state, grn_state,grpc_state, inv_state,  purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").find(:all, :conditions=>["order_type = ?", "#{type}"])
      end
    else
      unless current_user.warehouse.blank?
        if current_user.warehouse.group.present? && current_user.try(:roles).try(:first).try(:group_flag)
          po = PurchaseOrder.joins(:warehouse).select("DISTINCT ON (po_number) po_number, purchase_orders.id,state,asn_state, grn_state,grpc_state, inv_state,  purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").find(:all, :conditions=>["warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ?", "#{type}"])
        else
          po = current_user.warehouse.purchase_orders.select("DISTINCT ON (po_number) po_number, purchase_orders.id,asn_state, state,grn_state,grpc_state, inv_state,  purchase_orders.updated_at").order("po_number, purchase_orders.updated_at desc").find(:all, :conditions=>["order_type = ?", "#{type}"]) #, Time.now -- and Date(purchase_orders.updated_at)=Date(?)
        end
      end
    end

      case type
      when "#{PO}"
        count = {:new=>0, :open=>0, :on_time=>0, :on_time_less=>0, :late=>0, :late_less=>0, :expired=>0, :for=>"#{PO}"}
        unless po.blank?
        po.each do |p|
          case p.state
          when 0
            count[:new] +=1
          when 1
            count[:open] +=1
          when 2
            count[:on_time] +=1
          when 3
            count[:on_time_less] +=1
          when 4
            count[:late] +=1
          when 5
            count[:late_less] +=1
          when 6
            count[:expired] +=1
          end
        end
      end
    when "#{ASN}"
      count = {:new=>0, :read=>0, :for=>"#{ASN}"}
      unless po.blank?
        po.each do |p|
          case p.asn_state_name.to_s
          when "new"
            count[:new] +=1
          when "read"
            count[:read] +=1
          end
        end
      end
      when "#{INV}"
        count = {:new=>0, :printed=>0, :rejected=>0, :incomplete=>0, :completed=>0, :for=>"#{INV}"}
        unless po.blank?
          po.each do |p|
            case p.inv_state_name.to_s
              when "nil", "new"
                count[:new] +=1
              when "printed"
                count[:printed] +=1
              when "rejected"
                count[:rejected] +=1
              when "incomplete"
                count[:incomplete] +=1
              when "completed"
                count[:completed] +=1
            end
          end
        end

      when "#{GRN}"
        count = {:new=>0, :read=>0,:dispute=>0,:rev=>0, :accepted=>0, :for=>"#{GRN}"}
        unless po.blank?
          po.each do |p|
            case p.grn_state_name.to_s
            when "new"
              count[:new] +=1
            when "read"
              count[:read] +=1
            when "dispute"
              count[:dispute] +=1
            when "rev"
              count[:rev]  +=1
            when "accepted"
              count[:accepted] +=1
            end
          end
        end
      end
      return count
  end

  def self.count_disputed_po(current_user)
    arr = {}
    if current_user.has_role?(:superadmin)
      arr[:disp_grns] = PurchaseOrder.with_grn_state(:dispute,:rev).where(" Date(purchase_orders.created_at) = Date(?) and purchase_orders.is_history = ?", Date.today, false).count
      arr[:disp_grtn] = ReturnedProcess.with_state(:disputed, :rev).where(" Date(returned_processes.created_at) = Date(?) and returned_processes.is_history = ?", Date.today, 0).count
    elsif  !current_user.supplier.blank?
      if !current_user.supplier.group.blank?  && current_user.roles.first.group_flag
        arr[:disp_grns] = PurchaseOrder.joins(:supplier).with_grn_state(:dispute,:rev).where("suppliers.group_id = #{current_user.supplier.group.id} and Date(purchase_orders.created_at) = Date(?) and purchase_orders.is_history = ?", Date.today, false).count
        arr[:disp_grtn] = ReturnedProcess.joins(:purchase_order => :supplier).with_state(:disputed, :rev).where("suppliers.group_id = #{current_user.supplier.group.id} and  Date(returned_processes.created_at) = Date(?) and returned_processes.is_history = ?", Date.today, 0).count
      else
        arr[:disp_grns] = PurchaseOrder.joins(:supplier).with_grn_state(:dispute,:rev).where("purchase_orders.supplier_id = #{current_user.supplier.id} and Date(purchase_orders.created_at) = Date(?) and purchase_orders.is_history = ?", Date.today, false).count
        arr[:disp_grtn] = ReturnedProcess.joins(:purchase_order).with_state(:disputed, :rev).where("purchase_orders.supplier_id = #{current_user.supplier.id} and Date(returned_processes.created_at) = Date(?) and returned_processes.is_history = ?", Date.today, 0).count
      end
    else
      unless current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          arr[:disp_grns] = PurchaseOrder.joins(:warehouse).with_grn_state(:dispute,:rev).where("warehouses.group_id = #{current_user.warehouse.group.id} and  Date(purchase_orders.created_at) = Date(?) and purchase_orders.is_history = ?", Date.today, false).count
          arr[:disp_grtn] = ReturnedProcess.joins(:purchase_order => :warehouse).with_state(:disputed, :rev).where("warehouses.group_id = #{current_user.warehouse.group.id} and Date(returned_processes.created_at) = Date(?) and returned_processes.is_history = ?", Date.today, 0).count
        else
          arr[:disp_grns] = PurchaseOrder.joins(:warehouse).with_grn_state(:dispute,:rev).where("purchase_orders.warehouse_id = #{current_user.warehouse.id} and Date(purchase_orders.created_at) = Date(?) and purchase_orders.is_history = ?", Date.today, false).count
          arr[:disp_grtn] = ReturnedProcess.joins(:purchase_order => :warehouse).with_state(:disputed, :rev).where("purchase_orders.warehouse_id = #{current_user.warehouse.id} and Date(returned_processes.created_at) = Date(?) and returned_processes.is_history = ?", Date.today, 0).count
        end
      end
    end
    return arr
  end
  def generate_barcode
    p_arr = []
    p_barcode = self.supplier.barcode_settings_suppliers
    unless p_barcode.blank?
      p_barcode.each do |p|
        case p[:priority]
          when 1
            case p[:description].downcase
              when "po number"
                p_arr[0] = self.po_number
              when "grn number"
                p_arr[0] = self.grn_number
              when "invoice number"
                p_arr[0] = self.invoice_number
            end
          when 2
            case p[:description].downcase
              when "po number"
                p_arr[1] = self.po_number
              when "grn number"
                p_arr[1] = self.grn_number
              when "invoice number"
                p_arr[1] = self.invoice_number
            end
          when 3
            case p[:description].downcase
              when "po number"
                p_arr[2] = self.po_number
              when "grn number"
                p_arr[2] = self.grn_number
              when "invoice number"
                p_arr[2] = self.invoice_number
            end
        end
      end
      date = Time.now.to_f
      p_arr << date.to_s.split(".").join
      code = p_arr.join('').split(" ").join("")
      self.invoice_barcode = "#{code}"
      require 'barby'
      require 'barby/barcode/code_93'
      require 'barby/outputter/ascii_outputter'
      require 'barby/outputter/png_outputter'
      barcode = Barby::Code93.new(code)
      #check if dir barcode exist
      unless Dir.exist?("public/assets/barcode/")
         Dir.mkdir "#{Rails.root}/public/assets/barcode/"
      end
      File.open("public/assets/barcode/#{self.invoice_barcode}", 'w'){|f|
        f.write barcode.to_png(:height => 100, :margin => 5)
      }
      return self
    end
  end

  def po_except_attributes
    self.attributes.except("is_published","id", "updated_at", "created_at","supplier_id","user_id", "state", "asn_state", "grn_state","grpc_state","is_history","inv_state","warehouse_id", "is_completed")
  end

  def set_field(destination)
    self.supplier_id = destination.supplier_id
    self.user_id = destination.user_id
    self.state = destination.state
    self.asn_state = destination.asn_state
    self.grn_state = destination.grn_state
    self.grpc_state = destination.grpc_state
    self.is_history = destination.is_history
    self.inv_state = destination.inv_state
    self.warehouse_id = destination.warehouse_id
    self.is_completed = destination.is_completed
  end

  def self.save_retur_from_api(params)
    parent = ''
    params["data"].each do |p|
      #next if whse code or cre account code blank
      next if p['po_whse_code'].blank? || p['cre_accountcode'].blank?
      #check cres data if exist
      supplier = Supplier.where(:code=>p['cre_accountcode'].squish).first
      warehouse = Warehouse.where(:warehouse_code => p['po_whse_code'].squish).first

      #cek supplier per PO
      if supplier.blank?
        res_supplier = OffsetApi.connect_with_query("suppliers", "cre_accountcode", p['cre_accountcode'].squish)
        unless res_supplier.is_a?(Net::HTTPSuccess)
          return OffsetApi.eval_net_http(res_supplier)
        end
        result_supplier = JSON.parse(res_supplier.body)
        return -2 if result_supplier['data'].blank?
        supplier = Supplier.save_a_supplier_from_api(result_supplier)
        return supplier if !supplier.is_a?(Supplier)
      end

      #cek warehouse per PO
      if warehouse.blank?
        res_whs = OffsetApi.connect_without_offset_systbl("systable","#{p['po_whse_code'].squish}","WH")
        unless res_whs.is_a?(Net::HTTPSuccess)
         return OffsetApi.eval_net_http(res_whs)
        end
        result_whs = JSON.parse(res_whs.body)
        return -2 if result_whs['data'].blank?
        warehouse = Warehouse.save_a_warehouse_from_api(result_whs)
        return warehouse if !warehouse.is_a?(Warehouse)
      end

      if p['po_order_type'] == "R"
        #store return here
        if p['po_order_status'].to_s == "75"
          inv_parent = PurchaseOrder.with_inv_state(:completed).where(:po_number => p['po_order_no'].to_s, :order_type=>"#{INV}", :is_history => false, :is_completed => true).last
          if inv_parent.present?
            #=================== Create PO retur
              po_retur = PurchaseOrder.set_po(p)
              po_retur.invoice_number = inv_parent.invoice_number
              po_retur.supplier_id = inv_parent.supplier_id
              po_retur.warehouse_id = inv_parent.warehouse_id
              po_retur.order_type = "#{GRTN}"
            #===================================
            if po_retur.save
              new_retur = ReturnedProcess.set_retur(po_retur,p)
              if new_retur.is_a?(ReturnedProcess)
                return false unless new_retur.save
                send_email_notification_when_synch(new_retur)
              end
            end
          end
        end
      end
    end
    #ketika tidak ada data sama sekali yg bisa di pull oleh B2B
    #check = params["data"].collect{|p| "'#{p['po_order_no']}'" }.join(",")
    check = params["data"].collect{|p| "#{p['po_order_no']}" }
    check_all_retur = PurchaseOrder.with_inv_state(:completed).where("po_number IN (?)", check).where("order_type = ? AND is_history = ? AND is_completed = ?", "#{INV}", false, true).last
    return -1 if check_all_retur.blank?
    return OffsetApi.update_po_api_offset("#{GRTN}",params['count'])
  end

  def self.save_po_from_api(params)
    parent = ''
    params["data"].each do |p|
      #check existed_po
      next if self.where(:order_type => "#{PO}", :po_number => "#{p['po_order_no']}").present?
      #next if whse code or cre account code blank
      next if p['po_whse_code'].blank? || p['cre_accountcode'].blank?
      #check cres data if exist
      supplier = Supplier.where(:code=>p['cre_accountcode'].squish).first
      warehouse = Warehouse.where(:warehouse_code => p['po_whse_code'].squish).first

      #cek supplier per PO
      if supplier.blank?
        res_supplier = OffsetApi.connect_with_query("suppliers", "cre_accountcode", p['cre_accountcode'].squish)
        unless res_supplier.is_a?(Net::HTTPSuccess)
          return OffsetApi.eval_net_http(res_supplier)
        end
        result_supplier = JSON.parse(res_supplier.body)
        return -2 if result_supplier['data'].blank?
        supplier = Supplier.save_a_supplier_from_api(result_supplier)
        return supplier if !supplier.is_a?(Supplier)
      end

      #cek warehouse per PO
      if warehouse.blank?
        res_whs = OffsetApi.connect_without_offset_systbl("systable","#{p['po_whse_code'].squish}","WH")
        unless res_whs.is_a?(Net::HTTPSuccess)
         return OffsetApi.eval_net_http(res_whs)
        end
        result_whs = JSON.parse(res_whs.body)
        return -2 if result_whs['data'].blank?
        warehouse = Warehouse.save_a_warehouse_from_api(result_whs)
        return warehouse if !warehouse.is_a?(Warehouse)
      end

      if p['po_order_type'] == "P"
        new_po = PurchaseOrder.set_po(p)
        case p['po_order_status']
          when "40"
            #order type 'Purchase Order (PO)'
            new_po.set_normal_po(p)
          else
            next
        end

        new_po.set_protected_attr_po_from_api(supplier,warehouse)
        if !new_po.save
           return false
        else
          parent.save if parent.instance_of?(PurchaseOrder)
          puts "PO NUmber : #{new_po.po_number} Has been created"
          send_email_notification_when_synch(new_po)
        end
      end
    end
    return OffsetApi.update_po_api_offset("#{PO}", params['count'])
  end

  def self.save_grn_from_api(params)
    parent = ''
    params["data"].each do |param|
      #next if whse code or cre account code blank
      next if param['po_whse_code'].blank? || param['cre_accountcode'].blank?
      #check cres data if exist
      supplier = Supplier.where(:code => param['cre_accountcode'].squish).first
      warehouse = Warehouse.where(:warehouse_code => param['po_whse_code'].squish).first

      #cek supplier per PO
      if supplier.blank?
        res_supplier = OffsetApi.connect_with_query("suppliers", "cre_accountcode", param['cre_accountcode'].squish)
        unless res_supplier.is_a?(Net::HTTPSuccess)
          return OffsetApi.eval_net_http(res_supplier)
        end
        result_supplier = JSON.parse(res_supplier.body)
        return -2 if result_supplier['data'].blank?
        supplier = Supplier.save_a_supplier_from_api(result_supplier)
        return supplier if !supplier.is_a?(Supplier)
      end
      #cek warehouse per PO
      if warehouse.blank?
        res_whs = OffsetApi.connect_without_offset_systbl("systable","#{param['po_whse_code'].squish}","WH")
        unless res_whs.is_a?(Net::HTTPSuccess)
         return OffsetApi.eval_net_http(res_whs)
        end
        result_whs = JSON.parse(res_whs.body)
        return -2 if result_whs['data'].blank?
        warehouse = Warehouse.save_a_warehouse_from_api(result_whs)
        return warehouse if !warehouse.is_a?(Warehouse)
      end

      if param['po_order_type'] == "P"
        new_po = PurchaseOrder.set_po(param)
        case param['po_order_status']
          when "70"
            #order type 'Goods Receive Notes' (GRN)
            grn_parent = new_po.is_grn_po_parent_existed?(param['po_order_no'].to_s)

            # jika di PO tidak ada record dengan po number yg sama, maka skip
            unless grn_parent.instance_of?(PurchaseOrder)
              next
            end

            expired = grn_parent.is_expired?
            if !expired
              #check if asn existed
              grn_parent.open_po if grn_parent.new?

              asn = PurchaseOrder.where(:order_type=>"#{ASN}", :po_number=>grn_parent.po_number).first
              if asn.blank?
                asn = PurchaseOrder.new
                asn.order_type = "#{ASN}"
              else
                #publish asn if asn
                unless asn.is_published?
                  asn.is_published = true
                  #update detail asn
                end
              end

              new_po.set_normal_grn(param)
              asn.state = grn_parent.state
              asn.invoice_number = grn_parent.invoice_number
              asn.set_protected_attr_po_from_api(supplier,warehouse)
              return false if !asn.save
            else
              next
            end
          else
            next
        end

        new_po.set_protected_attr_po_from_api(supplier,warehouse)
        return false if !new_po.save

        parent.save if parent.instance_of?(PurchaseOrder)
        send_email_notification_when_synch(new_po)
      end
    end
    return OffsetApi.update_po_api_offset("#{GRN}", params['count'])
  end

  def is_expired?
    if self.new? || self.nil?
      now=Date.today.strftime("%d-%m-%Y")
      if now > self.due_date.strftime("%d-%is_expired?m-%Y")
        self.expire_po if self.can_expire_po?
        return true
      end
    end

    return false
  end

  def set_protected_attr_po_from_api(supplier, warehouse)
    self.supplier_id = supplier.id
    self.warehouse_id = warehouse.id
    self.is_completed = true
  end

  def set_po_without_warehouse_id_or_supplier_id(p)
    return true
  end

  def set_grn_without_warehouse_id_or_supplier_id(p)
    return true
  end

  def self.find_inv_history param_id
    self.where(is_history: true, po_number: PurchaseOrder.find(param_id).po_number, order_type: 'Invoice').limit(1).order('id DESC')
  end

  def self.find_grn_history param_id
    self.where(is_history: true, po_number: PurchaseOrder.find(param_id).po_number, order_type: 'Goods Receive Notes').limit(1).order('id DESC')
  end

  def self.find_grpc_history param_id
    self.where(is_history: true, po_number: PurchaseOrder.find(param_id).po_number, order_type: 'Goods Receive Price Confirmations').limit(1).order('id DESC')
  end

  def self.set_po(p)
    yr = p['po_date_stamp'].to_datetime.strftime("%Y")
    mt = p['po_date_stamp'].to_datetime.strftime("%m")
    dy = p['po_date_stamp'].to_datetime.strftime("%d")

    hr = p['po_time_stamp'].to_datetime.strftime("%H")
    mte = p['po_time_stamp'].to_datetime.strftime("%M")
    sec = p['po_time_stamp'].to_datetime.strftime("%S")

    updated_date = Date.new(yr.to_i, mt.to_i, dy.to_i).to_datetime + Time.parse("#{hr}:#{mte}:#{sec}").seconds_since_midnight.seconds
    return PurchaseOrder.new(:po_number => p["po_order_no"],
          :po_date => "#{p['po_order_date'].to_date}",
          :order_status => "#{p['po_order_status']}",
          :due_date => "#{p['po_arrival_date'].to_date}",
          :total_line_qty => p['total_line_qty'],
          :received_date =>"#{p['po_received_date'].to_date}",
          :total_qty => p['po_total_qty'],
          :invoice_number =>p['po_invoice_no'],
          :term => p['po_order_terms'],
          :currency_code => p['po_currency_code'],
          :initial_currency_rate => p['init_curr_rate'],
          :invoice_due_date => p['invoice_due_date'],
          :ordered_tax_amt => p['ordered_tax_amt'],
          :received_tax_amt => p['received_tax_amt'],
          :user_name => "#{p['po_user_name']}".squish,
          :received_total => p['received_total'],
          :order_total => p['po_order_total'],
          :updated_date => p['po_date_stamp'].to_datetime.strftime("%Y-%m-%d"),
          :updated_time => updated_date,
          :backorder_flag => p['backorder_flag'],
          :invoice_date => "#{(p['po_invoice_date'].blank?? '' : p['po_invoice_date'].to_date)}"
          )
  end

  def set_normal_po(p)
    self.order_type = "#{PO}"
  end

  def is_grn_po_parent_existed?(po_number)
    if parent = PurchaseOrder.with_state(:new,:open, :on_time, :on_time_but_less_than_100, :late, :late_but_less_than_100).where(:po_number => po_number, :order_type => "#{PO}",:is_completed=>true, :is_history=>false).first
      return parent
    end

    return false
  end

  def set_normal_grn(p)
    self.order_type = "#{GRN}"
    self.grn_number = "#{p['po_inwards_no'].squish}"
  end

  def is_grn_late(parent)
    if self.received_date > self.due_date
       self.state = 4
       parent.state = 4
    elsif self.received_date <= self.due_date
       self.state = 2
       parent.state = 2
    end
    self.grn_state = 1
  end

  def check_total_qty_parent_grn(total)
    if self.order_type == "#{PO}"
      state = self.state_name.to_s
      case state
        when 'on_time'
           if self.total_qty < total
             return self.fulfill_po_less if self.can_fulfill_po_less?
           end
        when 'late'
           if self.total_qty < total
             return self.fulfill_po_late_less if self.can_fulfill_po_late_less?
           end
      end
    end
  end

  def get_field_name_po(type)
    last_date_stamp = self.updated_time.strftime("%Y-%m-%d") rescue nil
    last_time_stamp = self.updated_time.strftime("%H:%M:%S") rescue nil

    field = []
    field << "date=" + last_date_stamp unless last_date_stamp.nil?
    field << "time=" + last_time_stamp unless last_time_stamp.nil?

    if type == "#{GRN}"
      field << "type=P"
      field << "status=70"
    elsif type == "#{PO}"
      field << "type=P"
      field << "status=40"
    else
      field << "type=R"
      field << "status=75"
    end

    return field.join("&")
  end

  def self.synch_po_now
    @last_po = PurchaseOrder.where(:order_type => "#{PO}", :is_history => false).order("updated_time ASC").last
    unless @last_po.blank?
      field = @last_po.get_field_name_po("#{PO}")
    end

    begin
      #pemanggilan API untuk PO setelah data PO sudah ada.
      unless field.nil?
        res = OffsetApi.get_data_transaction_from_api("purchorder", API_LIMIT, field)
      else
        offset = OffsetApi.where(:api_type=> "#{PO}").last.offset
        offset = 0 if offset.nil?
        #untuk memanggil API first time.
        res = OffsetApi.connect_with_only_order_offset("purchorder", API_LIMIT, offset, "40", "P")
      end
    rescue => e
      return 2 #mengebalikan status untuk service atau pun server mati pada API
    end

    unless res.is_a?(Net::HTTPSuccess)
      return OffsetApi.eval_net_http(res)
    end

    result = JSON.parse(res.body)
    return -1 if result['data'].blank?
    begin
      ActiveRecord::Base.transaction do
        unless PurchaseOrder.save_po_from_api(result)
           ActiveRecord::Rollback
           return false
        end
      end
      return true
    rescue => e
      ActiveRecord::Rollback
    end

    return false
  end

  def self.synch_grn_now
    @last_po = PurchaseOrder.where(:order_type => "#{GRN}", :is_history => false).order("updated_time ASC").last
    unless @last_po.blank?
      field = @last_po.get_field_name_po("#{GRN}")
    end

    begin
      #pemanggilan API untuk GRN setelah data GRN sudah ada.
      unless field.nil?
        res = OffsetApi.get_data_transaction_from_api("purchorder", API_LIMIT, field)
      else
        offset = OffsetApi.where(:api_type=> "#{GRN}").last.offset
        offset = 0 if offset.nil?
        #untuk memanggil API first time.
        res = OffsetApi.connect_with_only_order_offset("purchorder", API_LIMIT, offset, "70", "P")
      end
    rescue => e
      return 2 #mengebalikan status untuk service atau pun server mati pada API
    end

    unless res.is_a?(Net::HTTPSuccess)
      return OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)
    return -1 if result['data'].blank?
    begin
      ActiveRecord::Base.transaction do
        unless PurchaseOrder.save_grn_from_api(result)
           ActiveRecord::Rollback
           return false
        end
      end
      return true
    rescue => e
      ActiveRecord::Rollback
    end

    return false
  end

  def self.synch_retur_now
    #check offset
    @last_retur = PurchaseOrder.where(:order_type => "#{GRTN}").order("updated_time ASC").try(:last)
    unless @last_retur.blank?
      field = @last_retur.get_field_name_po("#{GRTN}")
    end

    begin
      #pemanggilan API untuk PO retur setelah data PO retur sudah ada.
      unless field.nil?
        res = OffsetApi.get_data_transaction_from_api("purchorder", API_LIMIT, field)
      else
        offset = OffsetApi.where(:api_type=> "#{GRTN}").last.offset
        offset = 0 if offset.nil?
        #untuk memanggil API first time.
        res = OffsetApi.connect_with_only_order_offset("purchorder", API_LIMIT, offset, "75", "R")
      end
    rescue => e
      return 2 #mengebalikan status untuk service atau pun server mati pada API
    end

    unless res.is_a?(Net::HTTPSuccess)
      return OffsetApi.eval_net_http(res)
    end

    result = JSON.parse(res.body)
    return -1 if result['data'].blank?

    begin
      ActiveRecord::Base.transaction do
        unless PurchaseOrder.save_retur_from_api(result)
          ActiveRecord::Rollback
          return false
        end
      end
      return true
    rescue => e
      ActiveRecord::Rollback
    end

    return false
  end

  def self.count_grn_states(date, state, type, current_user)
    if state == "new"
      if current_user.has_role? :superadmin
        pos = PurchaseOrder.where("order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
      elsif current_user.supplier.present?
        if current_user.supplier.group.present? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:supplier).where("suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
            .where(:is_history => false)
        else
          pos = PurchaseOrder.where("supplier_id = #{current_user.supplier.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        end
      elsif !current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:warehouse).where("warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
            .where(:is_history => false)
        else
          pos = PurchaseOrder.where("warehouse_id = #{current_user.warehouse.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        end
      end
    elsif state == 'pending'
      pos = PurchaseOrder.with_grn_state(state.to_sym)
      if current_user.has_role? :superadmin
        pos = pos.where("order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
      elsif current_user.supplier.present?
        if current_user.supplier.group.present? && current_user.roles.first.group_flag
          pos = pos.joins(:supplier).where("suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
        else
          pos = pos.where("supplier_id = #{current_user.supplier.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
        end
      elsif !current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          pos = pos.joins(:warehouse).where("warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
        else
          pos = pos.where("warehouse_id = #{current_user.warehouse.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
        end
      end
    elsif state == 'dispute'
      if current_user.has_role? :superadmin
        pos = PurchaseOrder.where("grn_state = 3 AND order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grn_number)
      elsif current_user.supplier.present?
        if current_user.supplier.group.present? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:supplier).where("grn_state = 3 AND suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", type, date)
            .group_by(&:grn_number)
        else
          pos = PurchaseOrder.where("grn_state = 3 AND supplier_id = #{current_user.supplier.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grn_number)
        end
      elsif !current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:warehouse).where("grn_state = 3 AND warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", type, date)
            .group_by(&:grn_number)
        else
          pos = PurchaseOrder.where("grn_state = 3 AND warehouse_id = #{current_user.warehouse.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grn_number)
        end
      end
    elsif state == 'rev'
      if current_user.has_role? :superadmin
        pos = PurchaseOrder.where("grn_state = 4 AND order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grn_number)
      elsif current_user.supplier.present?
        if current_user.supplier.group.present? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:supplier).where("grn_state = 3 AND suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", type, date)
            .group_by(&:grn_number)
        else
          pos = PurchaseOrder.where("grn_state = 4 AND supplier_id = #{current_user.supplier.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grn_number)
        end
      elsif !current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:warehouse).where("grn_state = 4 AND warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", type, date)
            .group_by(&:grn_number)
        else
          pos = PurchaseOrder.where("grn_state = 4 AND warehouse_id = #{current_user.warehouse.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grn_number)
        end
      end
    else
      pos = PurchaseOrder.with_grn_state(state.to_sym)
      if current_user.has_role? :superadmin
        pos = pos.where("order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
      elsif current_user.supplier.present?
        if current_user.supplier.group.present? && current_user.roles.first.group_flag
          pos = pos.joins(:supplier).where("suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        else
          pos = pos.where("supplier_id = #{current_user.supplier.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        end
      elsif !current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          pos = pos.joins(:warehouse).where("warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        else
          pos = pos.where("warehouse_id = #{current_user.warehouse.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        end
      end
    end
  end

  def self.count_grpc_states(date, state, type, current_user)
    if state == "unread"
      if current_user.has_role? :superadmin
        pos = PurchaseOrder.where("order_type = ? and to_char(po_date, 'YYYYMM') = ?","#{type}", date).where(:is_history => false)
      elsif !current_user.supplier.blank?
        if !current_user.supplier.group.blank? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:supplier).where("suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
            .where(:is_history => false)
        else
          pos = PurchaseOrder.where("supplier_id = #{current_user.supplier.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        end
      elsif !current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:warehouse).where("warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
            .where(:is_history => false)
        else
          pos = PurchaseOrder.where("warehouse_id = #{current_user.warehouse.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        end
      end
    elsif state == 'dispute'
      if current_user.has_role? :superadmin
        pos = PurchaseOrder.where("grpc_state = 3 AND order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grn_number)
      elsif current_user.supplier.present?
        if current_user.supplier.group.present? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:supplier).where("grpc_state = 3 AND suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", type, date)
            .group_by(&:grpc_number)
        else
          pos = PurchaseOrder.where("grpc_state = 3 AND supplier_id = #{current_user.supplier.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grpc_number)
        end
      elsif !current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:warehouse).where("grpc_state = 3 AND warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", type, date)
            .group_by(&:grpc_number)
        else
          pos = PurchaseOrder.where("grpc_state = 3 AND warehouse_id = #{current_user.warehouse.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grpc_number)
        end
      end
    elsif state == 'rev'
      if current_user.has_role? :superadmin
        pos = PurchaseOrder.where("grpc_state = 4 AND order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grn_number)
      elsif current_user.supplier.present?
        if current_user.supplier.group.present? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:supplier).where("grpc_state = 4 AND suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", type, date)
            .group_by(&:grn_number)
        else
          pos = PurchaseOrder.where("grpc_state = 4 AND supplier_id = #{current_user.supplier.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grn_number)
        end
      elsif !current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          pos = PurchaseOrder.joins(:warehouse).where("grpc_state = 4 AND warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", type, date)
            .group_by(&:grn_number)
        else
          pos = PurchaseOrder.where("grpc_state = 4 AND warehouse_id = #{current_user.warehouse.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:grn_number)
        end
      end
    else
      pos = PurchaseOrder.with_grpc_state(state.to_sym)
      if current_user.has_role? :superadmin
        pos = pos.where("order_type = ? and to_char(po_date, 'YYYYMM') = ?","#{type}", date).where(:is_history => false)
      elsif !current_user.supplier.blank?
        if !current_user.supplier.group.blank? && current_user.roles.first.group_flag
          pos = pos.joins(:supplier).where("suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        else
          pos = pos.where("supplier_id = #{current_user.supplier.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        end
      elsif !current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          pos = pos.joins(:warehouse).where("warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        else
          pos = pos.where("warehouse_id = #{current_user.warehouse.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
        end
      end
    end
  end

  def self.count_pos_statuses(date, state, type, current_user)
    arr = Array.new(13) {Array.new}
    pos = ''
    case type
      when "#{PO}"
        if state == 'new'
          if current_user.has_role? :superadmin
            pos = PurchaseOrder.where("order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
          elsif current_user.supplier.present?
            if current_user.supplier.group.present? && current_user.roles.first.group_flag
              pos = PurchaseOrder.joins(:supplier).where("suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
                .where(:is_history => false)
            else
              pos = current_user.supplier.purchase_orders.where("order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
            end
          elsif !current_user.warehouse.blank?
            if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
              pos = PurchaseOrder.joins(:warehouse).with_state(state.to_sym)
                .where("warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
            else
              pos = current_user.warehouse.purchase_orders.where("order_type = ? and to_char(po_date, 'YYYYMM') = ?","#{type}", date).where(:is_history => false)
            end
          end
        else
          if current_user.has_role? :superadmin
            pos = PurchaseOrder.with_state(state.to_sym).where("order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
          elsif current_user.supplier.present?
            if current_user.supplier.group.present? && current_user.roles.first.group_flag
              pos = PurchaseOrder.joins(:supplier).with_state(state.to_sym)
                .where("suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
            else
              pos = current_user.supplier.purchase_orders.with_state(state.to_sym).where("order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
            end
          elsif !current_user.warehouse.blank?
            if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
              pos = PurchaseOrder.joins(:warehouse).with_state(state.to_sym)
                .where("warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
            else
              pos = current_user.warehouse.purchase_orders.with_state(state.to_sym).where("order_type = ? and to_char(po_date, 'YYYYMM') = ?","#{type}", date).where(:is_history => false)
            end
          end
        end
      when "#{GRN}"
        pos = PurchaseOrder.count_grn_states(date, state, type, current_user)
      when "#{GRPC}"
        pos = PurchaseOrder.count_grpc_states(date, state, type, current_user)
      when "#{INV}"
        if state == "new"
          if current_user.has_role? :superadmin
            pos = PurchaseOrder.where("order_type = ? and to_char(po_date, 'YYYYMM') = ?","#{type}", date).where(:is_history => false)
          elsif !current_user.supplier.blank?
            if !current_user.supplier.group.blank? && current_user.roles.first.group_flag
              pos = PurchaseOrder.joins(:supplier).where("suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
                .where(:is_history => false)
            else
              pos = PurchaseOrder.where("supplier_id = #{current_user.supplier.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
            end
          elsif !current_user.warehouse.blank?
            if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
              pos = PurchaseOrder.joins(:warehouse).where("warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date)
                .where(:is_history => false)
            else
              pos = PurchaseOrder.where("warehouse_id = #{current_user.warehouse.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).where(:is_history => false)
            end
          end
        else
          pos = PurchaseOrder.with_inv_state(state.to_sym)
          if current_user.has_role? :superadmin
            pos = pos.where("order_type = ? and to_char(created_at, 'YYYYMM') = ?","#{type}", date).group_by(&:invoice_number)
          elsif !current_user.supplier.blank?
            if !current_user.supplier.group.blank? && current_user.roles.first.group_flag
              pos = pos.joins(:supplier).where("suppliers.group_id = #{current_user.supplier.group.id} and order_type = ? and to_char(created_at, 'YYYYMM') = ?", "#{type}", date).group_by(&:invoice_number)
            else
              pos = pos.where("supplier_id = #{current_user.supplier.id} and order_type = ? and to_char(po_date, 'YYYYMM') = ?", "#{type}", date).group_by(&:invoice_number)
            end
          elsif !current_user.warehouse.blank?
            if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
              pos = pos.joins(:warehouse).where("warehouses.group_id = #{current_user.warehouse.group.id} and order_type = ? and to_char(created_at, 'YYYYMM') = ?", "#{type}", date).group_by(&:invoice_number)
            else
              pos = pos.where("warehouse_id = #{current_user.warehouse.id} and order_type = ? and to_char(created_at, 'YYYYMM') = ?", "#{type}", date).group_by(&:invoice_number)
            end
          end
        end
      when "#{GRTN}"
        if state == "unread"
          pos = ReturnedProcess.with_state(state.to_sym, :nil)
        else
          pos = ReturnedProcess.with_state(state.to_sym)
        end
        if current_user.has_role? :superadmin
          pos = pos.where("to_char(rp_date, 'YYYYMM') = ?", date).where(:is_history => false)
        elsif !current_user.supplier.blank?
          if !current_user.supplier.group.blank? && current_user.roles.first.group_flag
            pos = pos.joins(:purchase_order => :supplier).where("suppliers.group_id = #{current_user.supplier.group.id} and to_char(rp_date, 'YYYYMM') = ?", date).where(:is_history => false)
          else
            pos = pos.joins(:purchase_order).where("purchase_orders.supplier_id = #{current_user.supplier.id} and to_char(rp_date, 'YYYYMM') = ?", date).where(:is_history => false)
          end
        elsif !current_user.warehouse.blank?
          if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
            pos = pos.joins(:purchase_order => :warehouse).where("warehouses.group_id = #{current_user.warehouse.group.id} and to_char(rp_date, 'YYYYMM') = ?", date).where(:is_history => false)
          else
            pos = pos.joins(:purchase_order).where("purchase_orders.warehouse_id = #{current_user.warehouse.id}  and to_char(rp_date, 'YYYYMM') = ?", date).where(:is_history => false)
          end
        end
    end

    return pos.count rescue 0
  end

  def self.stats_of_all_po_state(type, date, current_user)
    arr = {}
    if date.blank?
       date = Date.today.strftime("%Y%m")
    end
    case type
      when "#{PO}"
        arr[:new] = PurchaseOrder.count_pos_statuses(date, "new", "#{PO}",current_user)
        arr[:open] = PurchaseOrder.count_pos_statuses(date, "open", "#{PO}",current_user)
        arr[:on_time] = PurchaseOrder.count_pos_statuses(date, "on_time", "#{PO}",current_user)
        arr[:on_time_but_less_than_100] = PurchaseOrder.count_pos_statuses(date, "on_time_but_less_than_100", "#{PO}", current_user)
        arr[:late] = PurchaseOrder.count_pos_statuses(date, "late", "#{PO}", current_user)
        arr[:late_but_less_than_100] = PurchaseOrder.count_pos_statuses(date, "late_but_less_than_100", "#{PO}", current_user)
        arr[:expired] = PurchaseOrder.count_pos_statuses(date, "expired", "#{PO}", current_user)
        arr[:cancelled] = PurchaseOrder.count_pos_statuses(date, "cancelled", "#{PO}", current_user)
      when "#{ASN}"
        arr[:unread] = PurchaseOrder.count_pos_statuses(date, "unread", "#{ASN}", current_user)
        arr[:read] = PurchaseOrder.count_pos_statuses(date, "read", "#{ASN}", current_user)
      when "#{GRN}"
        arr[:new] = PurchaseOrder.count_pos_statuses(date, "new", "#{GRN}", current_user)
        arr[:disputed] = PurchaseOrder.count_pos_statuses(date, "dispute", "#{GRN}", current_user)
        arr[:revised] = PurchaseOrder.count_pos_statuses(date, "rev", "#{GRN}", current_user)
        arr[:pending] = PurchaseOrder.count_pos_statuses(date, "pending", "#{GRN}", current_user)
        arr[:accepted] = PurchaseOrder.count_pos_statuses(date, "accepted", "#{GRN}", current_user)
      when "#{GRPC}"
        arr[:unread] = PurchaseOrder.count_pos_statuses(date, "unread", "#{GRPC}", current_user)
        arr[:disputed] = PurchaseOrder.count_pos_statuses(date, "dispute", "#{GRPC}", current_user)
        arr[:revised] = PurchaseOrder.count_pos_statuses(date, "rev", "#{GRPC}", current_user)
        arr[:pending] = PurchaseOrder.count_pos_statuses(date, "pending", "#{GRN}", current_user)
        arr[:accepted] = PurchaseOrder.count_pos_statuses(date, "accepted", "#{GRPC}", current_user)
      when "#{INV}"
        arr[:new] = PurchaseOrder.count_pos_statuses(date, "new", "#{INV}", current_user)
        arr[:printed] = PurchaseOrder.count_pos_statuses(date, "printed", "#{INV}", current_user)
        arr[:incomplete] = PurchaseOrder.count_pos_statuses(date, "incomplete", "#{INV}", current_user)
        arr[:completed] = PurchaseOrder.count_pos_statuses(date, "completed", "#{INV}", current_user)
      when "#{GRTN}"
        arr[:unread] = PurchaseOrder.count_pos_statuses(date, "unread", "#{GRTN}", current_user)
        arr[:read] = PurchaseOrder.count_pos_statuses(date, "read", "#{GRTN}", current_user)
        arr[:received] = PurchaseOrder.count_pos_statuses(date, "received", "#{GRTN}", current_user)
        arr[:disputed] = PurchaseOrder.count_pos_statuses(date, "disputed", "#{GRTN}", current_user)
        arr[:rev] = PurchaseOrder.count_pos_statuses(date, "rev", "#{GRTN}", current_user)
        arr[:accepted] = PurchaseOrder.count_pos_statuses(date, "accepted", "#{GRTN}", current_user)
      else
        return 1
    end
    return arr
  end

  def update_is_create_payment_request_and_create_payment_request(user)
    begin
      ActiveRecord::Base.transaction do
        if self.update_attributes(:is_create_payment_request => true)
          create_pr = EarlyPaymentRequest.new
          create_pr.purchase_order_id = self.id
          create_pr.user_id = user.id
          create_pr.state = 0
          if create_pr.save
            PurchaseOrder.send_notifications(create_pr)
            create_pr.save_activity
            return true
          end
        end
      end
    rescue => e
      ActiveRecord::Rollback
    end

    return false
  end

  def self.DELAY_LEVEL_LIMIT
    1.minutes.from_now
  end

  def self.DELAY_LEVEL_LIMIT
    1.minutes.from_now
  end

  def self.delay_grtn
    1.minutes.from_now
  end

  def self.delay_notification
    1.minutes.from_now
  end

  def self.search_disputed_po(type, options=nil)
    p_month,p_year, results = "","", self.order("po_date DESC")

    if options[:date].present?
      if options[:date][:month].present?
        p_month = options[:date][:month]
      end

      if options[:date][:year].present?
        p_year = options[:date][:year]
      end
    else
      p_month = Date.today.month
      p_year = Date.today.year
    end

    c_type = type == "GRN" ? GRN : GRPC
    if options[:search].present?
      if options[:search][:supplier_code].present?
        supplier_id = Supplier.where(:code => options[:search][:supplier_code]).first
        results = where(:supplier_id => supplier_id)
      end
    end

    #cek date month dan date year
    if p_month.present?
      results = results.where("extract(month from purchase_orders.po_date) = ?", p_month)
    end

    if p_year.present?
      results = results.where("extract(year from purchase_orders.po_date) = ?", p_year)
    end

    return results.where("#{type.downcase}_state in (3,4)")
  end

  def po_change_status
    str = ""
    if self.grn_state_name.to_s == "dispute"
      str = "On Follow Customer"
    elsif self.grn_state_name.to_s == "rev"
      str = "On Follow Supplier"
    elsif self.grpc_state_name.to_s == "dispute"
      str = "On Follow Customer"
    elsif self.grpc_state_name.to_s == "rev"
      str = "On Follow Supplier"
    end
    return str
  end

  def self.get_asn_without_grn(options)
    if options[:search].present?
      if options[:search][:supplier_code].present?
        supplier_id = Supplier.where(:code => options[:search][:supplier_code]).first
        results = where(:order_type => "#{ASN}", :supplier_id => supplier_id).where("po_number not in (SELECT po_number FROM purchase_orders WHERE order_type = '#{GRN}')")
      else
        results = where(:order_type => "#{ASN}").where("po_number not in (SELECT distinct(po_number) FROM purchase_orders WHERE order_type = '#{GRN}')")
      end
    else
      results = where(:order_type => "#{ASN}").where("po_number not in (SELECT distinct(po_number) FROM purchase_orders WHERE order_type = '#{GRN}')")
    end
    return results.order("created_at DESC")
  end

  def self.print_to_xls(options, type, current_ability)
    book = Spreadsheet::Workbook.new
    header_column_bold = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :silver })
    header_value = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :xls_color_45 })
    detail_value = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :xls_color_49 })
    detail_column_bold = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :gray })
    curr_format = Spreadsheet::Format.new({:weight => :bold, :pattern => 1, :pattern_fg_color => :xls_color_49, :number_format => 'Rp #,##0.00' })

    if type == "pd"
      results = self.where(:is_history => false).accessible_by(current_ability).get_asn_without_grn(options)
      header_template = ["Supplier Code","Supplier Name","Store","Order No","Ordered", "Arrival" "Estimate Arrival Date"]
      details_template = ["","Item Code","Item Desc","Qty","UoM","Qty ASN"]
      sheet1 = book.create_worksheet :name => "Pending Delivery"
      new_line = 0
      #========================== HEADER ====================================
      7.times do |t|
        # ============  HEADER
        #column 0
        sheet1.row(0).default_format = header_column_bold
        sheet1[0, t] = header_template[t]
      end

      # ============= VALUE HEADER
      results.each_with_index do |po, i|
        new_line += 1
        sheet1.row(new_line).default_format = header_value
        sheet1[new_line, 0] = po.supplier.code
        sheet1[new_line, 1] = po.supplier.name
        sheet1[new_line, 2] = po.warehouse.warehouse_name
        sheet1[new_line, 3] = po.po_number
        sheet1[new_line, 4] = po.po_date.to_date.strftime("%d %B %Y") rescue ""
        sheet1[new_line, 5] = po.due_date.to_date.strftime("%d %B %Y") rescue ""
        sheet1[new_line, 6] = po.asn_delivery_date.strftime("%d %B %Y") rescue ""
        new_line += 1

        #get column detail
        7.times do |t2|
          sheet1[new_line, t2] = details_template[t2]
          sheet1.row(new_line).default_format = detail_column_bold
        end

        new_line += 1
        po.details_purchase_orders.order("seq ASC").each_with_index do |d, i2|
          sheet1.row(new_line).default_format = detail_value
          sheet1[new_line, 1] = d.product.code
          sheet1[new_line, 2] = d.product.name.gsub("<br/>","; ")
          sheet1[new_line, 3] = d.order_qty
          sheet1[new_line, 4] = d.product.unit_description
          sheet1[new_line, 5] = d.commited_qty
          new_line += 1
        end
      end

      path = "#{Rails.root}/public/purchase_order_xls/pd-excel-file.xls"
      #======================= END HEADER ===================================
    elsif type == "grn"
      results = accessible_by(current_ability).search_disputed_po("grn", options)
      header_template = ["Supplier Code","Supplier Name","Year","Month","Order No", "GRN No" "Status", "PIC"]
      details_template = ["","Item Code","Item Desc","Qty Customer","Qty Supplier","UoM"]
      sheet1 = book.create_worksheet :name => "On Going Disputed (GRN)"
      #========================== HEADER ====================================
      8.times do |t|
        # ============  HEADER
        #column 0
        sheet1.row(0).default_format = header_column_bold
        sheet1[0, t] = header_template[t]
      end
      new_line = 0

      # ============= VALUE HEADER
      results.each_with_index do |po, i|
        new_line += 1
        sheet1.row(new_line).default_format = header_value
        sheet1[new_line, 0] = po.supplier.code
        sheet1[new_line, 1] = po.supplier.name
        sheet1[new_line, 2] = po.po_date.to_date.year
        sheet1[new_line, 3] = po.po_date.to_date.strftime("%B")
        sheet1[new_line, 4] = po.po_number
        sheet1[new_line, 5] = po.grn_number
        sheet1[new_line, 6] = po.po_change_status
        sheet1[new_line, 7] = po.user.username
        new_line += 1

        #get column detail
        7.times do |t2|
          sheet1[new_line, t2] = details_template[t2]
          sheet1.row(new_line).default_format = detail_column_bold
        end

        new_line += 1
        po.details_purchase_orders.order("seq ASC").each_with_index do |d, i2|
          sheet1.row(new_line).default_format = detail_value
          sheet1[new_line, 1] = d.product.code
          sheet1[new_line, 2] = d.product.name.gsub("<br/>","; ")
          sheet1[new_line, 3] = d.received_qty
          sheet1[new_line, 4] = d.dispute_qty
          sheet1[new_line, 5] = d.product.unit_description
          new_line += 1
        end
      end

      path = "#{Rails.root}/public/purchase_order_xls/ongoing-dispute-grn-excel-file.xls"
      #======================= END HEADER ===================================
    elsif type == "grpc"
      results = accessible_by(current_ability).search_disputed_po("grpc", options)
      header_template = ["Supplier Code","Supplier Name","Year","Month","Order No", "GRPC No" "Status", "PIC"]
      details_template = ["","Item Code","Item Desc","Qty Customer","Qty Supplier", "UoM", "Price Customer", "Price Supplier", "Total Price Customer","Total Price Supplier"]
      sheet1 = book.create_worksheet :name => "On Going Disputed (GRPC)"
      #========================== HEADER ====================================
      8.times do |t|
        # ============  HEADER
        #column 0
        sheet1.row(0).default_format = header_column_bold
        sheet1[0, t] = header_template[t]
      end
      new_line = 0

      # ============= VALUE HEADER
      results.each_with_index do |po, i|
        new_line += 1
        sheet1.row(new_line).default_format = header_value
        sheet1[new_line, 0] = po.supplier.code
        sheet1[new_line, 1] = po.supplier.name
        sheet1[new_line, 2] = po.po_date.to_date.year
        sheet1[new_line, 3] = po.po_date.to_date.strftime("%B")
        sheet1[new_line, 4] = po.po_number
        sheet1[new_line, 5] = po.grpc_number
        sheet1[new_line, 6] = po.po_change_status
        sheet1[new_line, 7] = po.user.username
        new_line += 1

        #get column detail
        11.times do |t2|
          sheet1[new_line, t2] = details_template[t2]
          sheet1.row(new_line).default_format = detail_column_bold
        end

        new_line += 1
        po.details_purchase_orders.order("seq ASC").each_with_index do |d, i2|
          sheet1.row(new_line).default_format = detail_value
          sheet1[new_line, 1] = d.product.code
          sheet1[new_line, 2] = d.product.name.gsub("<br/>","; ")
          sheet1[new_line, 3] = d.received_qty
          sheet1[new_line, 4] = d.dispute_qty
          sheet1[new_line, 5] = d.product.unit_description
          sheet1[new_line, 6] = d.item_price
          sheet1[new_line, 7] = d.dispute_price
          sheet1.row(new_line).set_format(6, curr_format)
          sheet1.row(new_line).set_format(7, curr_format)
          sheet1[new_line, 8] = (d.item_price * d.received_qty)
          sheet1[new_line, 9] = (d.dispute_price * d.dispute_qty)
          sheet1.row(new_line).set_format(8, curr_format)
          sheet1.row(new_line).set_format(9, curr_format)
          sheet1.column(6).width = 17
          sheet1.column(7).width = 17
          sheet1.column(8).width = 17
          sheet1.column(9).width = 17
          new_line += 1
        end
      end

      path = "#{Rails.root}/public/purchase_order_xls/ongoing-dispute-grpc-excel-file.xls"
      #======================= END HEADER ===================================
    end
      book.write path
      return {"path" => path}
  end

  def self.print_to_pdf(options, type, current_ability)
    case type
    when "pd"
      results = where(:is_history => false).accessible_by(current_ability).get_asn_without_grn(options)
    when "grn"
      results = accessible_by(current_ability).search_disputed_po("grn", options)
    when "grpc"
      results = accessible_by(current_ability).search_disputed_po("grpc", options)
    end
    return results
  end

  def self.get_dispute_details(params, _hash_type)
    where("#{params[:type]}_number = ?", "#{_hash_type[:number_of]}").where(:order_type => _hash_type[:type], :is_history => false).where("#{params[:type].downcase}_state in (3,4)").order("created_at ASC")
  end

  def prep_json
    val = []
    val << "'b2b_po_order_no': '#{po_number}'"
    val << "'b2b_cre_accountcode': '#{supplier.code}'"
    val << "'b2b_po_order_date': '#{po_date}'"
    val << "'b2b_backorder_flag': '#{backorder_flag}'"
    val << "'b2b_po_whse_code': '#{warehouse.warehouse_code}'"
    val << "'b2b_po_order_total': '#{order_total}'"
    val << "'b2b_po_date_stamp': \"#{Time.now.strftime("%Y-%m-%d")}\""
    val << "'b2b_po_time_stamp': \"#{Time.now.strftime("%H:%M:%S")}\""
    val << "'b2b_flag': \"1\""
    val << "'b2b_po_total_qty': '#{total_qty}'"

    return "{#{val.join(",").gsub!("'", '"')}}"
  end
end #of class
