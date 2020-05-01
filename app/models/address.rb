class Address < ActiveRecord::Base
  belongs_to :location, polymorphic: true
  attr_accessible :name, :fax_no, :website,
                  :phone, :office_address, :accountcode,
                  :mobile_phone, :street, :suburb, :country, :postcode, :country_code,
                  :ausbar_code, :office_address
  attr_protected :location_id, :location_type
  before_save :get_supplier
  #author : Leonardo
  #desc : menyimpan data address untuk masing" supplier dan customer
  def self.save_name_and_address_from_api(params)
    addresses = self.order("id DESC")
    params["data"].each do |p|
      unless p["na_type"] == ""
        if p["na_type"].downcase != "c"
          unless addresses.pluck(:accountcode).include?("#{p["accountcode"]}")
            address = Address.new
            address.accountcode = p["accountcode"]
            address.name = p["na_company"]
            address.street = p["na_street"]
            address.suburb = p["na_suburb"]
            address.country = p["na_country"]
            address.postcode = p["postcode"]
            address.country_code = p["na_country_code"]
            address.phone = p["na_phone"]
            address.mobile_phone = p["na_phone_2"]
            address.fax_no = p["na_fax_no"]
            address.ausbar_code = p["na_ausbar_code"]
            address.office_address = ""
            address.save
          end
        end
      end
    end
  end

  #author : Leonardo
  #desc : mengambil ID supplier untuk masing" address
  def get_supplier
    supplier = Supplier.where(:code => self.accountcode).first
    self.supplier_id = supplier.id if supplier
  end

  def self.set_and_save_supplier_addr(addr,supplier)
    flag =false
    addr['data'].each do |a|
      if a['na_type'].squish.downcase == "c"
        supplier_addr = supplier.addresses.new(
          :name=>a['na_company'],
          :street=>a['na_street'],
          :suburb=>a['na_suburb'],
          :country=>a['na_country'],
          :postcode=>a['postcode'],
          :country_code=>a['na_country_code'],
          :phone => a["na_phone"],
          :mobile_phone => a["na_phone_2"],
          :fax_no => a["na_fax_no"],
          :ausbar_code => a["na_ausbar_code"]
          )
        return flag if !supplier_addr.save
      end
    end
    return flag = true
  end

  def self.set_and_save_whse_addr(addr,whse)
    flag =false
    addr['data'].each do |a|
      if a['na_type'].squish.downcase == "wh"
        whse_addr = whse.addresses.new(
          :name=>a['na_company'],
          :suburb=>a['na_suburb'],
          :country=>a['na_country'],
          :postcode=>a['postcode'],
          :country_code=>a['na_country_code'],
          :phone => a["na_phone"],
          :mobile_phone => a["na_phone_2"],
          :fax_no => a["na_fax_no"],
          :ausbar_code => a["na_ausbar_code"]
          )
        whse_addr.street = a['na_street'].blank? ? '' : a['na_street'].squish
        return flag if !whse_addr.save
      end
    end
    return flag = true
  end
end
