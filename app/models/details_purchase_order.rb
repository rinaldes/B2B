class DetailsPurchaseOrder < ActiveRecord::Base
  attr_accessible :delivery_date,:order_qty,:disc_rate,
                  :commited_qty,:received_qty,:received_qty,:dispute_qty,:reconciled_qty,
                  :unit_price,:dispute_price,:reconciled_price,:total_amount_before_tax,
                  :total_amount_after_tax,:service_level, :remark,:purchase_order_desc,
                  :product_desc,:unit_price,:item_description, :backorder_flag, :is_completed_invoice_to_api, :product_id
  attr_protected :purchase_order_id
  belongs_to :purchase_order
  belongs_to :product

  validates :commited_qty, presence: {:message => 'can not be blank'}

  def self.callback_podetails

  end

  def self.get_and_save_po_details_from_api(po)
    flag = false
    begin
      #polne dan polinetax wajib ada, jika tidak ada salah satu data tidak bisa muncul detailnya
      res= OffsetApi.connect_with_query("poline","po_order_no",po.po_number)
      restax = OffsetApi.connect_with_query("polinetax","polt_order_no",po.po_number)

      unless res.is_a?(Net::HTTPSuccess) || restax.is_a?(Net::HTTPSuccess)
        return flag = OffsetApi.eval_net_http(res) if !res.is_a?(Net::HTTPSuccess)
        return flag = OffsetApi.eval_net_http(restax) if !restax.is_a?(Net::HTTPSuccess)
      end
    rescue => e
      return flag = 3
    end
    result = JSON.parse(res.body)
    result_tax = JSON.parse(restax.body)

    if result['data'].blank? || result_tax['data'].blank?
      return flag = -1
    else
      begin
        ActiveRecord::Base.transaction do
          saved_detail = DetailsPurchaseOrder.save_details_po(result,result_tax,po)
          return flag = saved_detail if saved_detail != true
        end
        return flag = true
        rescue => e
          ActiveRecord::Rollback
          flag=false
        return flag
      end
    end
    return flag
  end

  def self.save_details_po(params_line,params_line_tax,po)
    flag = false
    params_line["data"].each do |d|
      if DetailsPurchaseOrder.check_is_detail_exist?(po,d['stock_code'].squish)
        flag = true
        next
      end

      product = Product.where(:code=>d['stock_code'].squish).first
      if product.blank?
         result_pr = OffsetApi.connect_with_query("stockMasters","stock_code",d['stock_code'])
         unless result_pr.is_a?(Net::HTTPSuccess)
           return flag = OffsetApi.eval_net_http(res)
         end
         result = JSON.parse(result_pr.body)
         return flag = -1 if result['data'].blank? || result['count'] != 1
         product = Product.save_a_product_from_api(result)
         return flag = false if !product.is_a?(Product)
      end
        detail = DetailsPurchaseOrder.setup_new_line(d,po)
        detail.insert_protected_attr(po,product)
        detail.insert_line_tax(params_line_tax)
        return flag = false  if !detail.save
        flag = true
    end
    return flag
  end

  def insert_line_tax(line_tax)
    line_tax['data'].each do |ltax|
      if ltax['polt_l_seq'].to_i == self.seq.to_i
         self.line_tax = ltax['polt_tax_rate']
      end
    end
  end

  def self.get_and_save_grn_details_from_api(grn)
    parent = PurchaseOrder.where(:po_number=>grn.po_number,:order_type=>"#{PO}").first
    return flag = false if parent.nil?
    total = 0
    begin
      ActiveRecord::Base.transaction do
        params["data"].each do |d|
          next if DetailsPurchaseOrder.check_is_detail_exist?(po,p['stock_code'].squish)
          product = Product.where(:code=>d['stock_code'].squish).first
          if product.nil?
            result_pr = OffsetApi.connect_with_query("stockMasters","stock_code",p['stock_code'])
            unless result_pr.is_a?(Net::HTTPSuccess)
              return flag = OffsetApi.eval_net_http(res)
            end
            result = JSON.parse(result_pr)
            return flag = -1 if result['data'].blank? || result['count'] != 1
            product = Product.save_a_product_form_api(result)
            return flag = false if !product.is_a?(Product)
          end
            detail = DetailsPurchaseOrder.setup_new_line(d)
            detail.insert_protected_attr(po,product)
            detail.insert_line_tax(params_line_tax)
            return flag =false  if !detail.save
            total += detail.received_qty.to_i
            flag = true
        end
        state = parent.state_name.to_s
        case state.downcase
          when "on_time", "late","open"
            parent.check_total_qty_parent_grn(total)
          else
            flag =false
        end
        return flag
      end
      rescue => e
        ActiveRecord::Rollback
        flag=false
        return flag
    end
  end

  def insert_protected_attr(po,product)
    self.purchase_order_id = po.id
    self.product_id = product.id
  end

  def self.setup_new_line(d,po)
     case "#{po.order_type}"
     when "#{PO}"
       detail = DetailsPurchaseOrder.new(
        :order_qty => d['po_order_qty'],
        :received_qty => d['po_received_qty'],
        :item_price => d['po_item_price'],
        :disc_rate => d['po_disc_rate'],
        :total_amount_before_tax => d['order_line_total'],
        :item_description => d['unit_description'],
        :seq => d['po_l_seq'].to_i,
        :commited_qty => 0,
        :backorder_flag => d['backorder_flag'])
     when "#{GRN}"
       detail = DetailsPurchaseOrder.new(
        :order_qty => d['po_order_qty'],
        :received_qty => d['po_received_qty'].to_i,
        :dispute_qty => d['po_received_qty'].to_i,
        :item_price => d['po_item_price'],
        :dispute_price => d['po_item_price'],
        :total_amount_before_tax => d['order_line_total'],
        :item_description => d['unit_description'],
        :seq => d['po_l_seq'].to_i,
        :commited_qty => self.get_commited_qty(d,po),
        :backorder_flag => d['backorder_flag'])
     when "#{INV}"
       detail = DetailsPurchaseOrder.new(
        :dispute_qty => d['po_order_qty'],
        :received_qty => d['po_received_qty'],
        :dispute_price => d['po_item_price'],
        :disc_rate => d['po_disc_rate'],
        :total_amount_before_tax => d['order_line_total'],
        :item_description => d['unit_description'],
        :seq => d['po_l_seq'].to_i,
        :commited_qty => 0,
        :backorder_flag => d['backorder_flag'])
     end
     return detail
  end

  def self.get_commited_qty(d,po)
    existed_asn = PurchaseOrder.where(:order_type => "#{ASN}", :po_number => "#{po.po_number}").last
    if existed_asn
      existed_asn.details_purchase_orders.each do |det|
        if d['po_l_seq'].to_i == det.seq.to_i
          return det.commited_qty.to_i
        end
      end
    else
      return d['po_received_qty'].to_i
    end
  end

  def self.check_is_detail_exist?(po,product_code)
    flag =false
    product = Product.where(:code=>product_code).first
    return flag=false if product.nil? # harus di ganti dengan ambil data product ke api
    check = DetailsPurchaseOrder.find(:all ,:conditions=>["product_id = ? and purchase_order_id = ?",product.id,po.id])
    flag  = true unless check.blank?
    return flag
  end
end
