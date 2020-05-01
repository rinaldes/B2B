class ReturnedProcessDetail < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :returned_process
  belongs_to :product
  attr_accessible :committed_qty, :return_qty, :received_qty, :received_as_retur_qty,:remark,:price_after_retur, :retur_desc,
                  :item_price, :item_description, :seq, :total_price_per_line

  validates :received_qty, :presence=>{:message=>"Can't be blank", :allow_nil=>false}, :numericality => {:message=>"Must be numeric"}
  validates :received_as_retur_qty, :presence=>{:message=>"Can't be blank", :allow_nil=>false}, :numericality => {:message=>"Must be numeric"}
  validate :received_qty_must_lteq_return_qty
  validate :received_as_retur_qty_must_lteq_received_qty

  def received_qty_must_lteq_return_qty
    if received_qty > return_qty
      errors.add(:received_qty, "Received qty must be equal or less than return qty")
    end
  end

  def received_as_retur_qty_must_lteq_received_qty
   	if received_as_retur_qty.to_f > received_qty.to_f
      errors.add(:received_as_retur_qty, "Received as retur qty must be equal or less than received qty")
   	end
  end

  def self.get_and_save_detail_retur_from_api(retur)
    flag = false
    backorder_flag = retur.purchase_order.backorder_flag
    res= OffsetApi.connect_with_query("poline","po_order_no",retur.rp_number, backorder_flag)
    #unless res.is_a?(Net::HTTPSuccess) || restax.is_a?(Net::HTTPSuccess)
    #  return flag = OffsetApi.eval_net_http(res) if !res.is_a?(Net::HTTPSuccess)
    #end
    result = JSON.parse(res.body)
    if result['data'].blank?
      return flag = -1
    else
      begin
        ActiveRecord::Base.transaction do
          saved_detail =ReturnedProcessDetail.save_detail_retur(result, retur)
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

  def self.save_detail_retur(params_line,retur)
    flag = false
    params_line["data"].each do |d|
      next if ReturnedProcessDetail.check_is_detail_exist?(retur,d['stock_code'].squish, d['backorder_flag'])
      product = Product.where(:code=>d['stock_code'].squish).first
      if product.nil?
         result_pr = OffsetApi.connect_with_query("stockMasters","stock_code",d['stock_code'])
         unless result_pr.is_a?(Net::HTTPSuccess)
           return flag = OffsetApi.eval_net_http(res)
         end
         result = JSON.parse(result_pr)
         return flag = -1 if result['data'].blank? || result['count'] != 1
         product = Product.save_a_product_from_api(result)
         return flag = false if !product.is_a?(Product)
      end
        detail = ReturnedProcessDetail.setup_new_line(d)
        retur.returned_process_details << detail
        detail.insert_protected_attr(retur,product)
        return flag = false  if !detail.save
        flag = true
    end
    return flag
  end

  def self.check_is_detail_exist?(retur,product_code,backorder_flag)
    flag =false
    product = Product.where(:code => product_code).first
    return flag=false if product.nil? # harus di ganti dengan ambil data product ke api
    check = ReturnedProcessDetail.find(:all ,:conditions => ["product_id = ? and returned_process_id = ?",product.id,retur.id])
    flag  = true unless check.blank? #&& backorder_flag == "AA"
    return flag
  end

  def self.setup_new_line(d)
    detail = ReturnedProcessDetail.new(
      :return_qty => d['po_order_qty'].to_f.abs,
      :item_price => d['po_item_price'].to_f.abs,
      :item_description => d['unit_description'],
      :seq => d['po_l_seq'],
      :total_price_per_line => d["order_line_total"])
    return detail
  end

  def insert_protected_attr(retur,product)
    self.returned_process_id = retur.id
    self.product_id = product.id
  end
end
