class ReturnedProcess < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :user
  belongs_to :purchase_order
  has_many :returned_process_details
  has_many :user_logs, :as => :log
  accepts_nested_attributes_for :returned_process_details, :allow_destroy => true, :reject_if => proc { |obj| obj.blank? }
  attr_accessible :returned_process_details_attributes, :rp_number, :rp_date,
                  :grand_total, :due_date, :purchase_order_desc, :updated_date, :updated_time
  attr_protected :purchase_order_id,:user_id,:state, :is_history
  include ApplicationHelper
  include ActionView::Helpers::NumberHelper

  state_machine initial: :unread do
    state :unread, value: 1
    state :read, value: 2
    state :received, value: 3
    state :disputed, value: 4
    state :rev, value: 5
    state :accepted, value: 6
    state :pending, value: 7

    event :to_unread do
      transition :nil => :unread
    end
    event :read do
      transition :unread => :read
    end
    event :receive do
      transition :read => :received
    end
    event :raise_dispute do
      transition [:received,:rev, :unread, :read] => :disputed, :if => lambda {|retur| retur.count_rev_of_retur <= 20 }
    end
    event :revise do
      transition :disputed => :rev
    end
    event :accept do
      transition [:rev, :received, :disputed, :read, :pending] => :accepted
    end
    event :pending do
      transition [:rev, :received, :disputed, :read] => :pending
    end

    after_transition :on => :receive, :do => :save_activity
    after_transition :on => :raise_dispute, :do => :save_activity
    after_transition :on => :revise, :do => :save_activity
    after_transition :on => :accept, :do => :save_activity
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

  scope :find_retur, lambda {|id| {:conditions => {:id => id, :is_history=>false, :is_completed=>true}}}
  scope :find_retur_history, lambda {|id| {:conditions=> {:id=>id,:is_completed=>true, :state=>[4,5,6]}}}

  def save_activity
    ul = UserLog.new(:log_type => self.class.model_name, :event => self.state_name.to_s, :transaction_type => "Return Process" )
    ul.user_id = self.user_id
    ul.log_id = self.id
    ul.save
  end

  def export_to_xls
    book = Spreadsheet::Workbook.new
    column_bold = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :silver })
    details_column = Spreadsheet::Format.new({:pattern => 1, :pattern_fg_color => :yellow })
    other_column = Spreadsheet::Format.new({:weight => :bold, :color => :white, :pattern => 1, :pattern_fg_color => :black })
    curr_format = Spreadsheet::Format.new({:weight => :bold, :pattern => 1, :pattern_fg_color => :yellow, :number_format => 'Rp #,##0.00' })
    cur_total_format = Spreadsheet::Format.new({:weight => :bold, :pattern => 1, :color => :white, :pattern_fg_color => :black, :number_format => 'Rp #,##0.00' })

    middle_template = ["No","Process","Date","Time","User","Remark"]
    left_header_template = ["Invoice Number","Retur Number","Warehouse","Supplier Code","Supplier Name","Order Type","Ordered","Arrival"]
    sheet1 = book.create_worksheet :name => "#{GRTN}"
    self_retur = ReturnedProcess.where(:rp_number => self.rp_number).where("state in (4,5,6)").order("created_at ASC")
    #diambil data GRN yang last untuk accepted
    details_accepted = self_retur.last.returned_process_details.order("seq ASC")
    details_title = ["Seq","Item Code","Barcode","Item Description","Retur QTY","Received QTY","Received as Retur QTY","UoM","Remark"]

#========================== HEADER ====================================
    8.times do |t|
      # ============  LEFT HEADER
      #column 0
      sheet1.row(t).default_format = column_bold
      sheet1[t, 0] = left_header_template[t]
    end

    # ============= VALUE LEFT HEADER
    sheet1[0, 2] = self.purchase_order.invoice_number
    sheet1[1, 2] = self.rp_number
    sheet1[2, 2] = self.purchase_order.warehouse.warehouse_name
    sheet1[3, 2] = self.purchase_order.supplier.code
    sheet1[4, 2] = self.purchase_order.supplier.name
    sheet1[5, 2] = self.purchase_order.order_type
    sheet1[6, 2] = convert_date(self.rp_date)
    sheet1[7, 2] = convert_date(self.purchase_order.due_date)
#======================= END HEADER ===================================

#======================= MIDDLE DETAIL TRANSACTION ===========================
    6.times do |t|
      sheet1[9, t] = middle_template[t]
      sheet1.row(9).default_format = column_bold
    end

    number = 0
    index = 0

    self_retur.each_with_index do |ret,i|
      i += 10
      index = i
      number += 1
      sheet1[i, 0] = number
      sheet1[i, 1] = ret.state_name.to_s == "rev" ? "Revision #{ret.revision_to}" : ret.state_name.to_s.capitalize
      sheet1[i, 2] = convert_date(ret.rp_date)
      sheet1[i, 3] = ret.created_at.to_datetime.new_offset(Rational(7,24)).strftime("%H:%M:%S")
      sheet1[i, 4] = ret.user.username
      sheet1[i, 5] = ret.remark
      sheet1.row(i).default_format = details_column
    end
  #======================================================================
    index += 2
    sheet1.row(index).default_format = other_column
    sheet1[index, 0] = "Disputed Lines"

  #===================== DETAIL TRANSACTION ACCEPTED ====================
    index += 1
    10.times do |d|
      sheet1[index, d] = details_title[d]
      sheet1.row(index).default_format = column_bold
    end

    index += 1
    index2 = index
    total_price = 0
    details_accepted.each_with_index do |d,i|
      sheet1[index+i,0] = d.seq
      sheet1[index+i,1] = d.product.code
      sheet1.column(1).width = 15
      sheet1[index+i,2] = d.product.apn_number
      sheet1.column(2).width = d.product.apn_number.to_s.length + 5
      sheet1[index+i,3] = d.product.name.gsub("<br/>","; ")
      sheet1[index+i,4] = d.return_qty
      sheet1[index+i,5] = d.received_qty
      sheet1[index+i,6] = d.received_as_retur_qty
      sheet1[index+i,7] = d.product.unit_description
      #sheet1[index+i,8] = d.item_price
      #sheet1.row(index+i).set_format(8, curr_format)
      #sheet1.column(8).width = 20
      sheet1[index+i,8] = d.remark
      index2 += 1
      sheet1.row(index+i).default_format = details_column
      #total_price += d.item_price
    end
    #index2 += 1
    #sheet1[index2, 6] = "Total Price"
    #sheet1[index2, 8] = total_price
    #sheet1.row(index2).default_format = cur_total_format
  #======================================================================
    path = "#{Rails.root}/public/purchase_order_xls/grtn_excel-file.xls"
    book.write path
    return {"path" => path}
  end

  def not_max_round current_user
    ReturnedProcess.where("user_id=#{current_user.id} AND rp_number='#{rp_number}'").count < DisputeSetting.find_by_transaction_type('Return Process').max_round-1
  end

  def last_update_by_other_user_current_by_current_user? current_user
    (user.roles.map(&:parent).include?(Role.find_by_name('customer')) && current_user.roles.map(&:parent).include?(Role.find_by_name('supplier')) || user.roles.map(&:parent).include?(Role.find_by_name('supplier')) && current_user.roles.map(&:parent).include?(Role.find_by_name('customer'))) rescue current_user.roles.map(&:parent).include?(Role.find_by_name('supplier'))
  end

  def self.search_report(options, user=nil)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'order number','return number'
          res = where("rp_number ilike ? ", "%#{options[:search][:detail]}%" )
        when 'invoice number'
          res = where("invoice_number ilike ? ", "%#{options[:search][:detail]}%" )
        when "status"
          status = options[:search][:detail].split(" ").join("_")
          begin
            res = with_state(status.to_sym)
            rescue => e
              return res = where(:state=>nil) #return empty array active record if state does not included valid state
          end
        end

        if user.try(:supplier).present?
          if user.try(:supplier).try(:group).present? && user.roles.first.try(:group_flag)
            res = res.joins(:purchase_order => :supplier).where("suppliers.group_id = ? AND returned_processes.is_history = ?", user.supplier.group.id, 0)
          else
            res = res.joins(:purchase_order).where("purchase_orders.supplier_id = ? AND returned_processes.is_history = ?", user.supplier.id, 0)
          end
        elsif user.try(:warehouse).present?
          if user.try(:warehouse).try(:group).present? && user.roles.first.try(:group_flag)
            res = res.joins(:purchase_order => :warehouse).where("warehouses.group_id = ? AND returned_processes.is_history = ?", user.warehouse.group.id, 0)
          else
            res = res.joins(:puchase_order).where("purchase_orders.warehouse_id = ? AND returned_processes.is_history = ?", user.warehouse.id, 0)
          end
        end

        if PurchaseOrder.check_between_two_date(options[:search][:period_1],options[:search][:period_2])
          res = res.where("DATE(rp_date) = ? ", PurchaseOrder.is_period_blank(options[:search][:period_1])) unless PurchaseOrder.is_period_blank(options[:search][:period_1]).blank?
        else
          res = res.where("DATE(rp_date) >= ? ", PurchaseOrder.is_period_blank(options[:search][:period_1])) unless PurchaseOrder.is_period_blank(options[:search][:period_1]).blank?
          res = res.where("DATE(rp_date) <= ? ", PurchaseOrder.is_period_blank(options[:search][:period_2])) unless PurchaseOrder.is_period_blank(options[:search][:period_2]).blank?
        end
      else
        res = where("rp_number ilike ?", "%#{options[:search][:detail]}%")
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
        when 'order number','return number'
          res = where("rp_number ilike ? ", "%#{options[:search][:detail]}%" )
        when 'invoice number'
          res = where("invoice_number ilike ? ", "%#{options[:search][:detail]}%" )
        when "status"
          status = options[:search][:detail].split(" ").map{ |s| s.to_sym }
          begin
            res = with_state(status)
            rescue => e
              return res = where(:state=>nil) #return empty array active record if state does not included valid state
          end
        end
        if PurchaseOrder.check_between_two_date(options[:search][:period_1],options[:search][:period_2])
          res = res.where("DATE(rp_date) = ? ", PurchaseOrder.is_period_blank(options[:search][:period_1])) unless PurchaseOrder.is_period_blank(options[:search][:period_1]).blank?
        else
          res = res.where("DATE(rp_date) >= ? ", PurchaseOrder.is_period_blank(options[:search][:period_1])) unless PurchaseOrder.is_period_blank(options[:search][:period_1]).blank?
          res = res.where("DATE(rp_date) <= ? ", PurchaseOrder.is_period_blank(options[:search][:period_2])) unless PurchaseOrder.is_period_blank(options[:search][:period_2]).blank?
        end
      else
        res = where("rp_number ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      res = scoped
    end
    return res
  end

  def self.send_grtn
    limit = LevelLimit.select('limit_date, warehouse_id, email_address_1, email_address_2, email_address_3, email_address_4, email_address_5').where("level_type = ?", "#{GRTN}")
    limit.each do |l|
      rp = ReturnedProcess.select('DISTINCT (rp_number) rp_number, id, rp_date, purchase_order_id').where("state != 3").order("id ASC")
      rp.each do |p|
        if l.warehouse_id == p.purchase_order.warehouse_id
          date = (Date.today - p.rp_date.to_date).to_i
          email = EmailLevelLimit.find_by_warehouse_id_and_email_type(l.warehouse_id, 'grtn')
          case date
          when l.limit_date
            unless l.email_address_1.nil?
              begin
                UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grtn(l.email_address_1, p, email)
              rescue => e
                OffsetApi.write_to_email_log(522,"Notifications GRTN")
              end
            else
              OffsetApi.write_to_email_log(204, "email address lvl1")
            end
          when l.limit_date * 2
            unless l.email_address_2.nil?
              begin
                UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grtn(l.email_address_2, p, email)
              rescue => e
                OffsetApi.write_to_email_log(522,"Notifications GRTN")
              end
            else
              OffsetApi.write_to_email_log(204, "email address lvl1")
            end
          when l.limit_date * 3
            unless l.email_address_3.nil?
              begin
               UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grtn(l.email_address_3, p, email)
              rescue => e
                OffsetApi.write_to_email_log(522,"Notifications GRTN")
              end
            else
              OffsetApi.write_to_euser_idmail_log(204, "email address lvl3")
            end
          when l.limit_date * 4
            unless l.email_address_4.nil?
              begin
                UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grtn(l.email_address_4, p, email)
              rescue => e
                OffsetApi.write_to_email_log(522,"Notifications GRTN")
              end
            else
              OffsetApi.write_to_email_log(204, "email address lvl4")
            end
          when l.limit_date * 5
            unless l.email_address_3.nil?
              begin
               UserMailer.delay(run_at: DELAY_LEVEL_LIMIT).mailer_grtn(l.email_address_5, p, email)
              rescue => e
                OffsetApi.write_to_email_log(522,"Notifications GRTN")
              end
            else
              OffsetApi.write_to_email_log(204, "email address lvl5")
            end
          end

        end
      end
     # user = ['chaerul.umam@wgs.co.id']
      #grtn = ReturnedProcess.last
      #email = EmailLevelLimit.find_by_warehouse_id(l.id)

      #UserMailer.mailer_grtn(user, grtn, email).deliver
    end
  end

  def count_rev_of_retur
    count = ReturnedProcess.find(:all, :conditions=>["rp_number = ? and state = 4","%#{self.rp_number}%"]).count
    return count
  end

  def insert_details_retur(params)
    self.returned_process_details.order("seq ASC").each_with_index do |d, index|
      params[:returned_process_details_attributes][index.to_s][:id] = d.id
    end
  end

  def receive_retur(params, user)
    flag=''
    self.insert_details_retur(params)
    begin
      ActiveRecord::Base.transaction do
        if self.update_attributes(params)
          self.user_id = user.id
          self.receive if self.can_receive?
          flag = true
        else
          flag = false
        end
      end

    rescue => e
     flag = false
      ActiveRecord::Rollback
    end
    PurchaseOrder.send_notifications(self)
    return flag
  end

  def self.create_disputed_retur(params, user)
    flag=''
    parent = ReturnedProcess.find(params[:id])
    params[:returned_process].merge! parent.attributes.except("id","created_at","purchase_order_id", "updated_at", "state","is_history","user_id","remark")
    parent.returned_process_details.order("seq ASC").each_with_index do |d,index|
      params[:returned_process][:returned_process_details_attributes][index.to_s].merge! d.attributes.except("id","updated_at","created_at","returned_process_id", "remark","product_id","received_qty","received_as_retur_qty")
    end

    new_dispute_retur = ReturnedProcess.new(params[:returned_process])
    new_dispute_retur.user_id = user.id
    new_dispute_retur.insert_protected_attr(parent)
    new_dispute_retur.insert_product_id_to_retur_details(parent)
    new_dispute_retur.remark = params[:returned_process][:remark]
    parent.is_history = true
    begin
      ActiveRecord::Base.transaction do
        if new_dispute_retur.can_raise_dispute? && parent.save
          new_dispute_retur.raise_dispute
        end
      end
      flag = new_dispute_retur
      ret = new_dispute_retur.get_push_cre_trans_to_api
    rescue => e
     flag = false
      ActiveRecord::Rollback
    end
    PurchaseOrder.send_notifications(new_dispute_retur)
    return flag
  end

  def insert_product_id_to_retur_details(parent, follow_state=nil)
    parent.returned_process_details.order("seq ASC").each_with_index do |d, index|
      self.returned_process_details[index].product_id = d.product_id
      if follow_state == "accepted"
        self.returned_process_details[index].received_qty = d.received_qty
        self.returned_process_details[index].received_as_retur_qty = d.received_as_retur_qty
      end
    end
  end

  def insert_protected_attr(parent)
    self.purchase_order_id = parent.purchase_order_id
    self.state = parent.state
    self.is_completed = parent.is_completed
  end

  def self.create_revised_retur(prev_retur, params, user)
    flag =false
    revision_to = self.where(:rp_number => "#{prev_retur.rp_number}").with_state(:rev).count + 1
    disputed_retur = ReturnedProcess.find(params[:id])
    params[:returned_process].merge! disputed_retur.attributes.except("id","created_at","purchase_order_id", "updated_at", "state","is_history","user_id","remark","revision_to")
    disputed_retur.returned_process_details.order("seq ASC").each_with_index do |d,index|
      params[:returned_process][:returned_process_details_attributes][index.to_s].merge! d.attributes.except("id","updated_at","created_at","returned_process_id", "remark","product_id","received_qty","received_as_retur_qty")
    end
    new_revised_retur = ReturnedProcess.new(params[:returned_process])
    new_revised_retur.user_id = user.id
    new_revised_retur.insert_protected_attr(disputed_retur)
    new_revised_retur.insert_product_id_to_retur_details(disputed_retur)
    new_revised_retur.remark = params[:returned_process][:remark]
    new_revised_retur.revision_to = revision_to
    disputed_retur.is_history = true
    begin
     ActiveRecord::Base.transaction do
       if new_revised_retur.can_revise? && disputed_retur.save
         new_revised_retur.revise
          flag = new_revised_retur
       else
          flag = new_revised_retur
       end
     end
     rescue => e
      flag =false
       ActiveRecord::Rollback
     end
     PurchaseOrder.send_notifications(new_revised_retur)
     return flag
  end

  def can_be_revised? current_user
    return false if current_user.warehouse.blank?
    dispute_setting = DisputeSetting.find_by_transaction_type('Return Process')
    current_level = UserLevelDispute.where("user_id=#{current_user.id} AND dispute_setting_id=#{dispute_setting.id}").last
    return true if ReturnedProcess.where("user_id=#{current_user.id} AND rp_number='#{rp_number}'").count < dispute_setting.max_round && UserLevelDispute.where("dispute_setting_id=#{dispute_setting.id} AND level > #{current_level.level}").present?
    po_count = ReturnedProcess.where("user_id=#{current_user.id} AND rp_number='#{rp_number}' AND state=5").count
    if GeneralSetting.where(:desc => "Last RP Approval").first.value == "Customer"
      current_user.warehouse.present? && po_count < dispute_setting.max_round-1
    else
      current_user.warehouse.present? && po_count < dispute_setting.max_round
    end
  end

  def self.create_accepted_retur(params,user)
    flag= ''
    retur = ReturnedProcess.find(params[:id])
    params[:returned_process]= {:returned_process_details_attributes=>{}}
    retur.returned_process_details.order("seq asc").each_with_index do |d, index|
      params[:returned_process][:returned_process_details_attributes]["#{index}"] = d.attributes.except("id", "returned_process_id", "created_at", "updated_at", "product_id", "received_qty",
        "received_as_retur_qty", "user_id")
    end
    params[:returned_process].merge! retur.attributes.except("id","user_id","created_at","updated_at","purchase_order_id","is_history","state","remark")
    new_accepted_retur = ReturnedProcess.new params[:returned_process]
    new_accepted_retur.user_id = user.id
    new_accepted_retur.insert_protected_attr(retur)
    new_accepted_retur.insert_product_id_to_retur_details(retur, "accepted")
    retur.is_history = true
    begin
      if GeneralSetting.find_by_desc('Last RP Approval').value == 'Supplier' && user.supplier.present? || GeneralSetting.find_by_desc('Last RP Approval').value == 'Customer' && user.warehouse.present?
        ActiveRecord::Base.transaction do
          if new_accepted_retur.can_accept? && retur.save
             new_accepted_retur.accept
             flag = new_accepted_retur
           else
            flag = false
          end
        end
        ret = new_accepted_retur.get_push_cre_trans_to_api
        flag= new_accepted_retur
      else
        ActiveRecord::Base.transaction do
          if new_accepted_retur.can_accept? && retur.save
             new_accepted_retur.pending
             flag = new_accepted_retur
           else
            flag = false
          end
        end
        flag= new_accepted_retur
      end
    rescue => e
      flag=false
      ActiveRecord::Rollback
    end
    PurchaseOrder.send_notifications(new_accepted_retur)
    return flag
  end

  def self.count_grtn_today_statuses(current_user)
    if current_user.has_role?(:superadmin)
      returs = ReturnedProcess.select("DISTINCT ON (rp_number) rp_number, returned_processes.id, returned_processes.state,  returned_processes.updated_at").order("rp_number, returned_processes.created_at desc").where("Date(returned_processes.updated_at)=Date(?) and returned_processes.is_history = 0", Time.now)
    elsif  !current_user.supplier.blank?
      if !current_user.supplier.group.blank?  && current_user.roles.first.group_flag
        returs = ReturnedProcess.joins(:purchase_order => :supplier).select("DISTINCT ON (rp_number) rp_number, returned_processes.id, returned_processes.state, returned_processes.updated_at").order("rp_number, returned_processes.updated_at desc").where("suppliers.group_id = #{current_user.supplier.group.id} and returned_processes.is_history = 0 and Date(returned_processes.updated_at)=Date(?)", Time.now)
      else
        returs = ReturnedProcess.joins(:purchase_order).select("DISTINCT ON (rp_number) rp_number, returned_processes.id, returned_processes.state, returned_processes.updated_at").order("rp_number, returned_processes.updated_at desc").where("purchase_orders.supplier_id = #{current_user.supplier.id} and returned_processes.is_history = 0 and Date(returned_processes.updated_at)=Date(?)", Time.now)
      end
    else
      unless current_user.warehouse.blank?
        if !current_user.warehouse.group.blank? && current_user.roles.first.group_flag
          returs = ReturnedProcess.joins(:purchase_order => :warehouse).select("DISTINCT ON (rp_number) rp_number, returned_processes.id, returned_processes.state, returned_processes.updated_at").order("rp_number, returned_processes.updated_at desc").where("warehouses.group_id = #{current_user.warehouse.group.id} and returned_processes.is_history = 0 and Date(returned_processes.updated_at)=Date(?)", Time.now)
        else
          returs = ReturnedProcess.joins(:purchase_order).select("DISTINCT ON (rp_number) rp_number, returned_processes.id, returned_processes.state, returned_processes.updated_at").order("rp_number, returned_processes.updated_at desc").where("purchase_orders.warehouse_id = #{current_user.warehouse.id} and returned_processes.is_history = 0 and Date(returned_processes.updated_at)=Date(?)", Time.now)
        end
      end
    end

    count = {:unread=>0, :read=>0, :received=>0, :disputed=>0, :rev=>0,:accepted=>0, :for=>"#{GRTN}"}
    unless returs.blank?
      returs.each do |r|
        case r.state_name.to_s
          when "unread", "nil"
            count[:unread] +=1
          when "read"
            count[:read] +=1
          when "received"
            count[:received] +=1
          when "disputed"
            count[:disputed] +=1
          when "rev"
            count[:rev] +=1
          when "accepted"
            count[:accepted] +=1
        end
      end
    end
    return count
  end

  def self.set_retur(parent,p)
    new_retur = ReturnedProcess.new(:rp_number=>p['po_order_no'], :rp_date=>"#{p['po_order_date'].to_date}")
    new_retur.invoice_number = p['po_invoice_no']
    new_retur.purchase_order_id = parent.id
    new_retur.is_completed = true
    #update date stamp dan time stamp untuk invoice untuk nantinya pengecekan retur ketika synch GRTN lewat API
      parent.updated_date = p['po_date_stamp'].to_date.strftime("%Y-%m-%d")
      parent.updated_time = p['po_time_stamp'].to_datetime.strftime("%H:%M:%S")
      parent.save
    #new_retur.user_id = user.id
    return new_retur
  end

  def self.set_po_for_retur(p)
    flag = false
    supplier = Supplier.where(:code=>p['cre_accountcode']).first
    warehouse = Warehouse.where(:warehouse_code=>p['po_whse_code']).first
    new_po = PurchaseOrder.set_po(po)
    new_po.set_normal_po(p)
    new_po.state = 1
    if !warehouse.nil? && !supplier.nil?
      new_po.set_protected_attr_po_from_api(supplier,warehouse)
    else
      #get warehouse or supplier from api
    end
    return flag = new_po if new_po.save
  end

  def self.search_reporting(options)
    p_month,p_year, results = "","", self.order("rp_date DESC")

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

    unless options[:search].blank?
      if options[:search][:supplier_code].present?
        supplier_id = Supplier.where(:code => options[:search][:supplier_code]).first
        results = joins(:purchase_order).where("purchase_orders.supplier_id = ?", supplier_id)
      end
    end

    #cek date month dan date year
    if p_month.present?
      results = results.where("extract(month from returned_processes.rp_date) = ?", p_month)
    end

    if p_year.present?
      results = results.where("extract(year from returned_processes.rp_date) = ?", p_year)
    end

    return results
  end

  def self.print_to_xls(options, current_ability)
    book = Spreadsheet::Workbook.new
    header_column_bold = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :silver })
    detail_column_bold = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :gray })
    header_value = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :xls_color_45 })
    detail_value = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :xls_color_49 })
    results = self.where(:is_history => false).accessible_by(current_ability).search_reporting(options)
    header_template = ["Supplier Code","Supplier Name", "Warehouse","Year","Month","Return No"]
    details_template = ["","Item Code","Item Desc","Return Qty", "Received Qty", "Received as Retur Qty", "UoM", "Reason"]
    sheet1 = book.create_worksheet :name => "Returned Histories"
    #========================== HEADER ====================================
    8.times do |t|
      # ============  HEADER
      #column 0
      sheet1.row(0).default_format = header_column_bold
      sheet1[0, t] = header_template[t]
    end
    new_line = 0

    # ============= VALUE HEADER
    results.each_with_index do |rp, i|
      new_line += 1
      sheet1.row(new_line).default_format = header_value
      sheet1[new_line, 0] = rp.purchase_order.supplier.code
      sheet1[new_line, 1] = rp.purchase_order.supplier.name
      sheet1[new_line, 2] = rp.purchase_order.warehouse.warehouse_name
      sheet1[new_line, 3] = rp.rp_date.to_date.year
      sheet1[new_line, 4] = rp.rp_date.to_date.strftime("%B")
      sheet1[new_line, 5] = rp.rp_number
      new_line += 1

      #get column detail
      9.times do |t2|
        sheet1[new_line, t2] = details_template[t2]
        sheet1.row(new_line).default_format = detail_column_bold
      end

      new_line += 1
      rp.returned_process_details.order("seq ASC").each_with_index do |d, i2|
        sheet1.row(new_line).default_format = detail_value
        sheet1[new_line, 1] = d.product.code
        sheet1[new_line, 2] = d.product.name.gsub("<br/>","; ")
        sheet1[new_line, 3] = d.return_qty
        sheet1[new_line, 4] = d.received_qty
        sheet1[new_line, 5] = d.received_as_retur_qty
        sheet1[new_line, 6] = d.product.unit_description
        sheet1[new_line, 7] = d.remark
        new_line += 1
      end
    end

    path = "#{Rails.root}/public/purchase_order_xls/ongoing-dispute-grpc-excel-file.xls"
    #======================= END HEADER ===================================
    book.write path
    return {"path" => path}
  end

  def self.print_to_pdf(options, current_ability)
    return self.where(:is_history => false).accessible_by(current_ability).search_reporting(options)
  end

  def self.get_search_retur(params)
    where(:is_history => false).with_state(:accepted).with_payment_state(:unused).joins(:purchase_order => :supplier).where("suppliers.code LIKE '%#{params[:supplier]}%' OR suppliers.name LIKE '%#{params[:supplier]}%'")
  end

  # Upload data retur ke pronto
  def respond_to_retur(params, user)
    unless self.remark.blank?
      return self.get_push_cre_trans_to_api
    end
    return false
  end

  def is_current?
    ReturnedProcess.where("user_id=#{current_user.id} AND rp_number='#{@retur.rp_number}'").count < DisputeSetting.find_by_transaction_type('Return Process').max_round-1
  end

  def get_push_cre_trans_to_api
    begin
      po = self.purchase_order
      date = Time.now.to_date.strftime("%Y-%m-%d")

      values = "{" +
          "\"b2b_cre_accountcode\": \"#{po.supplier.code}\"," +
          "\"b2b_cr_tr_other_side\": \"#{self.invoice_number}\"," +
          "\"b2b_cr_tr_pay_by_date\": \"#{self.rp_date}\"," +
          "\"b2b_cr_tr_date\": \"#{date}\"," +
          "\"b2b_cr_tr_date_stamp\": \"#{Time.now.strftime("%Y-%m-%d")}\"," +
          "\"b2b_cr_tr_time_stamp\": \"#{Time.now.strftime("%H:%M:%S")}\"," +
          "\"b2b_cr_tr_reference\": \"#{self.invoice_number}\"," +
          "\"b2b_cr_tr_po_order_no\": #{po.po_number.to_i}," +
          "\"b2b_backorder_flag\": \"#{po.backorder_flag}\"," +
          "\"b2b_cr_tr_details\": \"#{self.user.username}\"," +
          "\"b2b_cr_tr_amount\": #{self.returned_process_details.map{|rtd|rtd.received_as_retur_qty*rtd.item_price}.sum}," +
          "\"b2b_cr_tr_invoice_date\": \"#{self.rp_date}\"," +
          "\"b2b_cr_tr_tax_amount\": #{po.tax_amount.to_f}," +
          "\"b2b_cr_tr_other_side\": \"#{po.tax_invoice_number}\"," +
          "\"b2b_retention_approved\": \"1\"" +
        "}"

      req_cre_trans = OffsetApi.get_push_invoice("b2btempcretrans/create", values)
    rescue => e
      return 2 #mengebalikan status untuk service atau pun server mati pada API
    end

    if req_cre_trans.is_a?(Net::HTTPSuccess)
      self.get_push_po_line po
      return true
    else
      return OffsetApi.eval_net_http(req_cre_trans)
    end
  end

  def get_push_po_line(po)
    po = PurchaseOrder.find_by_po_number_and_order_type(po.po_number, 'Purchase Order')
    self.returned_process_details.order("seq ASC").each do |det|
      values = "{" +
          "\"b2b_po_order_no\": #{self.rp_number.to_i}," +
          "\"b2b_backorder_flag\": \"#{po.backorder_flag}\"," +
          "\"b2b_po_l_seq\": #{det.seq.to_i}," +
          "\"b2b_stock_code\": \"#{det.try(:product).try(:code)}\"," +
          "\"b2b_po_order_qty\": #{DetailsPurchaseOrder.find_by_product_id_and_purchase_order_id(det.product_id, po.id).order_qty.to_f}," +
          "\"b2b_po_received_qty\": #{det.received_as_retur_qty.to_f}," +
          "\"b2b_po_item_price\": #{det.item_price.to_f}" +
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
end
