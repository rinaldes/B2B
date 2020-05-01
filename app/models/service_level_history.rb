class ServiceLevelHistory < ActiveRecord::Base
	belongs_to :supplier
	belongs_to :purchase_order
  attr_accessible :po_type, :total_sl
  attr_protected :supplier_id, :purchase_order_id
  belongs_to :supplier

  paginates_per PER_PAGE
  max_paginates_per 100

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

    left_header_template = ["PO Number", "Warehouse", "Ship To", " Order Type", "Officer", "Supplier Code", "Supplier Name", "Phone Number", "Ordered", "Arrival", "Last Update By"]
    sheet1 = book.create_worksheet :name => "#{GRPC}"
    self_order = PurchaseOrder.where(:po_number => self.po_number, :order_type => "#{PO}").order("created_at ASC")
    #diambil data GRPC yang last untuk accepted
    details_accepted = self_order.last.details_purchase_orders.order("seq ASC")
    details_title = ["Seq","Item Code","Barcode","Item Description","Commited QTY","Received QTY","UoM","Item Price","Dispute Price","Remark"]
#Supplier Code	Supplier Name	Month	Year	Order No	Case Order	Line Order	On Time Delivery Order	Total Service Level
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

  def self.count_sl_total_per_tr(year, option=nil)
    default_sl = ServiceLevel.first
    avg = 0
    arr = Array.new(13) {Array.new}
    arr_s = Array.new(13) {Array.new}
    (1..12).each{|a|
      end_time = a == 12 ? "#{year+1}-#{sprintf('%02d', 1)}-01 00:00:00" : "#{year}-#{sprintf('%02d', a+1)}-01 00:00:00"
      if option.is_a? Integer

        asn = PurchaseOrder.where("order_type = 'Advance Shipment Notifications' AND created_at BETWEEN '#{year}-#{sprintf('%02d', a)}-01 00:00:00' AND '#{end_time}'")
          .where(:supplier_id => option)
        asn_details = DetailsPurchaseOrder.where("purchase_order_id IN (#{asn.map(&:id).push(0).join(',')})") rescue []

        qty = asn_details.map(&:order_qty).sum.to_f>0 ? (asn_details.map(&:commited_qty).sum.to_f/asn_details.map(&:order_qty).sum.to_f*default_sl.sl_qty) : 0


        po = PurchaseOrder.where("order_type = 'Purchase Order' AND po_number IN ('#{asn.map(&:po_number).join("','")}')")
        po_details = DetailsPurchaseOrder.where("purchase_order_id IN (#{po.map(&:id).push(0).join(',')})") rescue []

        line = (asn_details.count.to_f/po_details.count*default_sl.sl_line) if po_details.count>0

        po.each{|p|
          if p.received_date > p.due_date
            en = supplier.extra_notes.first

            unless en.blank?
              en = ExtraNote.find(:all, :conditions=>["en_type ilike ?","%df%"]).first
            end
            days = en[:text].split(/[[:alpha:]]/) rescue []
            exp = 0
            days.each do |day|
              exp = day.to_i if day.to_i != 0
            end
            expired_date = self.due_date + exp
            diff = self.received_date - self.due_date
            time_count = (exp-diff)/exp rescue 0
          end
        }
        if line.to_f > 0 && qty.to_f > 0
          time_count = default_sl.sl_time-time_count.to_f
          timo = a
          time = Time.utc(year,timo,1).to_time.to_i * 1000
        end
        arr[a][0] = time
        arr[a] << (qty.to_f+line.to_f+time_count.to_f).round(2)
      else
        asn = PurchaseOrder.where("order_type = 'Advance Shipment Notifications' AND extract(year from purchase_orders.created_at) = ?" , year).accessible_by(option)
      end
    }
        arr.each_with_index do |a,index|
          sum = 0
          avg = 0

          arr[index].each_with_index do |x,index|
            sum +=x if index != 0
          end

          if sum == 0
            arr_s[index] << arr[index][0].to_i
            arr_s[index] << sum
          else
	          avg = sum/(arr[index].count-1)
	          arr_s[index] << arr[index][0].to_i
	          arr_s[index] << avg
          end
        end

        i = 0
        num = arr_s.count-1
        while num > i  do
           if arr_s[num] == [0,0]
             arr_s[num] = []
           else
             break
           end
           num -=1
        end
    return arr_s
  end

  def self.count_sl_total_per(year, option=nil)
  	avg = 0
    arr = Array.new(13) {Array.new}
    arr_s = Array.new(13) {Array.new}
    if option.is_a? Integer
    	slh = ServiceLevelHistory.where("extract(year from service_level_histories.created_at) = ?" , year).where(:supplier_id => option)
    else
    	slh = ServiceLevelHistory.where("extract(year from service_level_histories.created_at) = ?" , year).accessible_by(option)
    end
    total = slh.count
    slh.each do |s|
      tot = s.total_sl.to_f
      timo = s.created_at.strftime('%m').to_s
      time = Time.utc(year,timo,1).to_time.to_i * 1000
      case s.created_at.strftime('%B').downcase
	      when "january"
	      	arr[1][0] = time
	        arr[1] << tot
	      when "february"
	      	arr[2][0] = time
	        arr[2] << tot
	      when "march"
	      	arr[2][0] = time
	      	arr[3] << tot
	      when "april"
	      	arr[4][0] = time
	      	arr[4] << tot
	      when "may"
	      	arr[5][0] = time
	      	arr[5] << tot
	      when "june"
	      	arr[6][0] = time
            arr[6] << tot
 	      when "july"
 	      	arr[7][0] = time
 	      	arr[7] << tot
	      when "august"
	      	arr[8][0] = time
	      	arr[8] << tot
	      when "september"
	      	arr[9][0] = time
	      	arr[9] << tot
	      when "october"
	      	arr[10][0] = time
	      	arr[10] << tot
	      when "november"
	      	arr[11][0] = time
	      	arr[11] << tot
	      when "december"
	      	arr[12][0] = time
	      	arr[12] << tot
      end
    end
    arr.each_with_index do |a,index|
      sum = 0
      avg = 0

      arr[index].each_with_index do |x,index|
        sum +=x if index != 0
      end

      if sum == 0
        arr_s[index] << arr[index][0].to_i
        arr_s[index] << sum
      else
	      avg = sum/(arr[index].count-1)
	      arr_s[index] << arr[index][0].to_i
	      arr_s[index] << avg
      end
    end

    i = 0
    num = arr_s.count-1
    while num > i  do
       if arr_s[num] == [0,0]
         arr_s[num] = []
       else
         break
       end
       num -=1
    end
    return arr_s
  end

  def self.search(options)
    p_month,p_year, results = "","", self.order("created_at DESC")

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
        results = where(:supplier_id => supplier_id)
	    end
  	end

    #cek date month dan date year
    if p_month.present?
      results = results.where("extract(month from service_level_histories.created_at) = ?", p_month)
    end

    if p_year.present?
      results = results.where("extract(year from service_level_histories.created_at) = ?", p_year)
    end

  	return results
  end

  def self.print_to_xls(options,current_ability)
    results = self.search(options).accessible_by(current_ability)
    book = Spreadsheet::Workbook.new
    column_bold = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :silver })
    header_value = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :xls_color_45 })
    column_format_percent =
    header_template = ["Supplier Code","Supplier Name","Year","Month","Order No","Case Order","Line Order","On Time Delivery Order","Total Service Level"]
    sheet1 = book.create_worksheet :name => "Service Level Supplier"
    #========================== HEADER ====================================
    9.times do |t|
      # ============  HEADER
      #column 0
      sheet1.row(0).default_format = column_bold
      sheet1[0, t] = header_template[t]
    end

    # ============= VALUE HEADER
    results.each_with_index do |sl, i|
      i += 1
      sheet1.row(i).default_format = header_value
      sheet1[i, 0] = sl.supplier.code
      sheet1[i, 1] = sl.supplier.name
      sheet1[i, 2] = sl.purchase_order.po_date.to_date.year
      sheet1[i, 3] = sl.purchase_order.po_date.to_date.strftime("%B")
      sheet1[i, 4] = sl.purchase_order.po_number
      sheet1[i, 5] = ReportsController.helpers.service_level_percentation(sl.supplier_id, sl.purchase_order)[:sl_order_total].to_f.round(2)
      sheet1[i, 6] = ReportsController.helpers.service_level_percentation(sl.supplier_id, sl.purchase_order)[:sl_line_total].to_f.round(2)
      sheet1[i, 7] = ReportsController.helpers.service_level_percentation(sl.supplier_id, sl.purchase_order)[:sl_time_total].to_f.round(2)
      sheet1[i, 8] = sl.total_sl.to_f
    end

    path = "#{Rails.root}/public/purchase_order_xls/grn_excel-file.xls"
    book.write path
    return {"path" => path}
#======================= END HEADER ===================================
  end

  def self.print_to_pdf(options, current_ability)
    return self.search(options).accessible_by(current_ability)
  end

end
