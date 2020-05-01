class SuppliersProduct < ActiveRecord::Base
  belongs_to :product
  belongs_to :supplier
  attr_accessible :last_buy_date
  attr_protected :supplier_id, :product_id, :last_buy_price

  paginates_per PER_PAGE

  def self.save_suppliers_products_from_api(params)
    params["data"].each do |p|
      product= Product.find(:all, :select=>[:id],  :conditions=>["code ilike ?","%#{p['stock_code']}%"]).last
      supplier = Supplier.find(:all, :select=>[:id], :conditions=>["code ilike ?","%#{p['cre_accountcode']}%"]).last
      if !product.nil? && !supplier.nil?
         check = SuppliersProduct.find(:all, :select=>[:id], :conditions=>["supplier_id = ? and product_id = ?",supplier.id,product.id])
         unless check.blank? || check.nil?
           ps = SuppliersProduct.new
           ps.supplier_id = supplier.id
           ps.product_id = product.id
           ps.last_buy_date = p["last_buy_date"]
           ps.last_buy_price = p["last_buy_price"]
           ps.save
         end
      end
    end
  end

 def self.get_and_save_product_suppliers_from_api(params,product)
    params['data'].each do |sp|
      supplier = Supplier.where(:code=>sp['cre_accountcode'].squish).first
      if supplier.nil?
         res = OffsetApi.connect_with_query("suppliers","cre_accountcode",sp['cre_accountcode'].squish)
         next if  !res.is_a?(Net::HTTPSuccess)
         result = JSON.parse(res.body)
         next if result['data'].blank?
         save_supplier = Supplier.save_a_supplier_from_api(result)
         next if !save_supplier.instance_of?(Supplier)
      end
      product.suppliers << supplier if !supplier.nil?
    end
    return true
 end
end
