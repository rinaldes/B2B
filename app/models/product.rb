class Product < ActiveRecord::Base
 	has_many :suppliers_products
  has_many :details_purchase_orders
 	has_many :suppliers, through: :suppliers_products
  has_many :warehouses_products
  has_many :warehouses, through: :warehouses_products

  attr_accessible :name, :code, :unit_price, :unit_qty, :barcode, :apn_number,
        :unit_description, :import_tarif, :convertion_factor, :pack_cubic_size, :pack_weight, :brand

  paginates_per 10
  max_paginates_per 100

  def self.search(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'name'
          where("products.name ilike ?", "%#{options[:search][:detail]}%")
          when 'code'
            where("products.code ilike ?", "%#{options[:search][:detail]}%")
            when 'supplier'
              joins(:suppliers).where("suppliers.name ilike ?", "%#{options[:search][:detail]}%")
        end
      else
         where("products.name ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      scoped
    end
  end

  def self.save_products_from_api(params)
    flag = false
    begin
      ActiveRecord::Base.transaction do
        params['data'].each do |p|
          next if p['stock_code'].blank?
          product  = Product.where(:code=>p['stock_code'].squish).first
          if product.blank?
             new_product = Product.new(
              :name=>"#{product_desc_array(p).squish}",
              :code => p['stock_code'].squish,
              :unit_price => p['stk_price_per'],
              :unit_qty => p['stk_unit_desc'].squish,
              :barcode => p[''],
              :apn_number => p['stk_apn_number'].squish,
              :unit_description => p['stk_unit_desc'].squish,
              :import_tarif => p['tariff_code'].squish,
              :convertion_factor => p['factor'],
              :pack_cubic_size => p['pack_cubic_size'],
              :pack_weight => p['stk_pack_weight'],
              :brand => p["stk_brand"])
            if new_product.save
              product_suppliers = new_product.get_and_save_product_suppliers_from_api
              if product_suppliers != true
                ActiveRecord::Rollback
                #jika mau dikeluarin pesan, tambahkan return untuk dibawah ini
                flag = product_suppliers
              else
               flag = true
              end
            else
              ActiveRecord::Rollback
              return flag = false
            end
          else
            flag = true
          end
        end
      end
    rescue => e
      ActiveRecord::Rollback
      return flag = false
    end
    return flag
  end

  def get_and_save_product_suppliers_from_api
    flag = false
    get_api_to = "stksupplier"
    res = OffsetApi.connect_with_query(get_api_to,"stock_code",self.code.squish)
    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)
    return flag = -2 if result['data'].blank?
    supplier_products = SuppliersProduct.get_and_save_product_suppliers_from_api(result,self)
    if supplier_products
      return flag = true
    else
      return flag
    end
  end

  def self.product_desc_array(p)
    product_desc = []
    product_desc << p['stk_description'].squish unless p['stk_description'].squish.blank?
    product_desc << p['stk_desc_line_2'].squish unless p['stk_desc_line_2'].squish.blank?
    product_desc << p['stk_desc_line_3'].squish unless p['stk_desc_line_3'].squish.blank?
    return product_desc.join("<br/>")
  end

  def self.callback_products
    require "net/http"
    require "uri"

    request_api = "#{api_call('api')}/stockMasters?field_name=stock_code,stk_description,stk_desc_line_2, stk_desc_line_3, stock_group, stk_apn_number, stk_unit_desc, tariff_code, factor, pack_cubic_size, stk_pack_weight, stk_price_per, stk_unit_desc"
    url = URI.parse(request_api)
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end
    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    res = req.request(http)
    result = JSON.parse(res.body)
    Product.save_products_from_api(result)
  end

  def self.save_a_product_from_api(params)
    params['data'].each do |p|
      new_product = Product.new(
        :name=>"#{product_desc_array(p)}",
        :code => p['stock_code'].squish,
        :unit_price => p['stk_price_per'],
        :barcode => p[''],
        :unit_qty => p['stk_unit_desc'],
        :apn_number => p['stk_apn_number'],
        :unit_description => p['stk_unit_desc'],
        :import_tarif => p['tariff_code'],
        :convertion_factor => p['factor'],
        :pack_cubic_size => p['pack_cubic_size'],
        :pack_weight => p['stk_pack_weight'],
        :brand => p["stk_brand"]
        )
      return flag = false if !new_product.save
      flag = new_product
      return flag
    end
  end

  def callback_api_product_based_on_code
    res = OffsetApi.connect_with_query("stockMasters", "stock_code", "#{self.code}")
    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)

    if result['data'].blank?
      return flag = -1
    else
      product_update = self.update_a_product_from_api(result)
      if product_update
        flag = true
      else
        flag = false
      end
    end
    return flag
  end

  def update_a_product_from_api(params)
    params['data'].each do |p|
      if self.code.downcase == p['stock_code'].downcase.squish
        self.name = "#{Product.product_desc_array(p)}"
        self.code = p['stock_code']
        self.unit_price = p['stk_price_per']
        self.unit_qty = p['stk_unit_desc']
        self.barcode = p['']
        self.apn_number = p['stk_apn_number']
        self.unit_description = p['stk_unit_desc']
        self.import_tarif = p['tariff_code']
        self.convertion_factor = p['factor']
        self.pack_cubic_size = p['pack_cubic_size']
        self.pack_weight = p['stk_pack_weight']
      end
      if self.save
        flag = true
      else
        flag = false
      end
      return flag
    end
  end

  def self.synch_products_periodically
    api = OffsetApi.where(:api_type=>"Product").first
    unless api.blank?
      status = api.availability_status
      while status
        offset = api.offset
        begin
          res = OffsetApi.connect_with_offset("stockMasters",API_LIMIT,offset)
          rescue => e
          OffsetApi.write_to_crontab_log(502,"Products")
          break
        end
        unless res.is_a?(Net::HTTPSuccess)
           Offset.write_to_crontab_log(502,"Products")
          break
        end
        result = JSON.parse(res.body)
        if result['data'].blank?
          OffsetApi.change_avalaible_status(api.api_type, false)
          OffsetApi.write_to_crontab_log(204,"Products")
          status = false
        else
          begin
          ActiveRecord::Base.transaction do
            save_product = Product.save_products_from_api(result)
            if save_product != true
              status = save_product
            else
              OffsetApi.update_po_api_offset("Product",result['count'])
            end
          end
          rescue => e
          ActiveRecord::Rollback
            status=false
             OffsetApi.write_to_crontab_log(500,"Products")
            break
          end
        end
      end
    end
  end

  def self.synch_products_now
    #check offset
    flag =false
    offset = OffsetApi.get_offset("Product")
    begin
      res = OffsetApi.connect_with_offset("stockMasters",API_LIMIT,offset)
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
        save_product = Product.save_products_from_api(result)
        return flag = save_product if save_product  != true
        if  OffsetApi.update_po_api_offset("Product",result['count'])
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

  def self.api_call(type)
    return ApiSetting.finds(type)
  end

  def export_to_xls
    book = Spreadsheet::Workbook.new
    column_bold = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :silver })
    left_header_title = ['Item Code','Item Desc.','APN Num.','Brand','Unit Desc.','Convertion Factor','Pack Desc.','Pack Cubic Size','Pack Weight','Impor Tarif']
    details_header = Spreadsheet::Format.new({:weight => :bold, :pattern => 1, :pattern_fg_color => :blue, :color => :white })
    detail_header_title = ['Supplier Code','Supplier Name','Level','Service Level','Address','Last Update','Item Last Buy Price']

    sheet1 = book.create_worksheet :name => 'Products'
    index = 0

    10.times do |t|
      # ============  LEFT HEADER
      #column 0
      sheet1.row(t).default_format = column_bold
      sheet1[t, 0] = left_header_title[t]
      index += 1
    end
    sheet1[0, 1] = self.code
    sheet1[1, 1] = self.name.html_safe
    sheet1[2, 1] = self.apn_number
    sheet1[3, 1] = self.brand
    sheet1[4, 1] = self.unit_description
    sheet1[5, 1] = self.convertion_factor
    sheet1[6, 1] = self.pack_description
    sheet1[7, 1] = self.pack_cubic_size
    sheet1[8, 1] = self.pack_weight
    sheet1[9, 1] = self.import_tarif

    sheet1.row(10).default_format = details_header
    sheet1[10, 0] = 'Product Details'

    7.times do |t|
      sheet1[11, t] = detail_header_title[t]
      sheet1.row(11).default_format = column_bold
    end
    index += 2

    self.suppliers_products.each_with_index do |supl, i|
      sheet1[i+index, 0] = supl.supplier.code
      sheet1[i+index, 1] = supl.supplier.name
      sheet1[i+index, 2] = supl.supplier.level
      sheet1[i+index, 3] = supl.supplier.service_level
      sheet1[i+index, 4] = supl.supplier.addresses.pluck(:name).join(",") rescue ''
      sheet1[i+index, 5] = supl.supplier.updated_at
      sheet1[i+index, 6] = supl.last_buy_price
    end

    path = "#{Rails.root}/public/purchase_order_xls/grtn_excel-file.xls"
    book.write path
    return {"path" => path}
  end
end
