class Supplier < ActiveRecord::Base
  has_many :childs, :class_name => "Supplier",:foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Supplier",:foreign_key => "parent_id"
  belongs_to :group, :conditions => ['groups.group_type = ?', 'Supplier']
  has_many :addresses, as: :location
  has_many :suppliers_products
  has_many :products, through: :suppliers_products
  has_many :users
  has_many :purchase_orders
  has_many :payments
  belongs_to :service_level
  has_many :barcode_settings_suppliers
  after_save :save_default_priority_barcode
  has_many :payment_vouchers
  has_many :extra_notes
  has_many :suppliers_notifications, :class_name => 'SuppliersNotifications'
  has_many :notifications, :through=> :suppliers_notifications
  has_many :service_level_histories

  attr_accessor :service_level_code, :barcode_1, :barcode_2, :barcode_3, :description
  #validates :level, presence: {allow_nil: false, allow_blank:false}, numericality: {allow_blank: false, allow_nil: false}
  attr_accessible :name, :group, :parent, :tax_of, :code, :phone_number, :level, :sl_time_total, :sl_line_total, :sl_order_total
  attr_protected :service_level_id
  paginates_per PER_PAGE
  max_paginates_per 100
  def self.search(options)
    unless options[:search].blank?
      if options[:search][:supplier_code].present?
        where("suppliers.code ilike ?", "%#{options[:search][:supplier_code]}%")
      elsif options[:search][:supplier_name].present?
        where("suppliers.name ilike ?", "%#{options[:search][:supplier_name]}%")
      elsif options[:search][:supplier_level].present?
        where("level = ?", "#{options[:search][:supplier_level]}")
      else
        where("suppliers.code ilike ?", "%#{options[:search][:supplier_code].strip}%")
      end
    else
      scoped
    end
  end

  def save_default_priority_barcode
    unless self.barcode_settings_suppliers.present?
      3.times do |t|
        t += 1
        insert_priority_barcode = BarcodeSettingsSupplier.new
        insert_priority_barcode.number = t
        insert_priority_barcode.priority = t
        insert_priority_barcode.supplier_id = self.id
        insert_priority_barcode.description = (t == 1 ? "PO Number" : t == 2 ? "GRN Number" : "Invoice Date")
        insert_priority_barcode.save
      end
    end
  end

  def self.save_suppliers_from_api(params)
    flag = false
    params['data'].each do |s|
      supplier = Supplier.where(:code=>"#{s['cre_accountcode']}".squish)
      if supplier.blank?
        #get group supplier first
        group = Group.where(:code => "#{s['cr_supplier_grp']}".squish).first
        if group.blank?
          #get group from api and save it
          group = Supplier.get_and_save_suppliers_group_from_api(s['cr_supplier_grp'])
          unless group
            ActiveRecord::Rollback
            return flag = group
          end
        end

        supplier = Supplier.where(:code => "#{s['cre_accountcode']}".squish).first
        if supplier.blank?
          new_supplier = Supplier.new(
            :name => (s['cr_shortname'].blank?? '' : s['cr_shortname'].squish),
            :code => s['cre_accountcode'].squish,
            :level => 1)
          new_supplier.service_level_total = 0
          new_supplier.group_id = group.id if group.instance_of? Group
          new_supplier.last_purchase = s['last_purchase']
          new_supplier.last_payment = s['last_payment']
          new_supplier.account_opened = s['cr_date_created']
          return flag = false if !new_supplier.save
          save_address = new_supplier.get_and_save_address_from_api
          if save_address != true
            ActiveRecord::Rollback
            return flag = save_address
          else
             flag = true
          end
        end
      else
        flag = true
      end
    end
    return flag
  end

  def self.get_and_save_suppliers_group_from_api(group_code)
    flag = false
    supplier_group = "systable"
    res = OffsetApi.connect_without_offset_systbl(supplier_group, group_code, "RV")
    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)
    return flag = -2 if result['data'].blank?
    supplier_group = Group.set_and_save_a_supplier_group(result)
    if supplier_group.instance_of? Group
      flag = supplier_group
    end
    return flag
  end

  def self.callback_suppliers(limit)
    flag= false
    offset = OffsetApi.where(:api_type=>"Supplier").last.offset
    offset = 0 if offset.nil?
    res = OffsetApi.connect_with_offset("Supplier",limit,offset)
    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)
    if result['data'].blank?
      return flag = 2 if OffsetApi.update_data_status_api_to_nil("Supplier")
    else
      suppliers_save = Supplier.save_suppliers_from_api(result)
      if suppliers_save != true
          return flag = suppliers_save
      else
         flag = true
      end
    end
    return flag
  end

  def update_barcode_settings(supplier_priority)
    self.barcode_settings_suppliers.each_with_index do |barcode_settings_supplier, index|
      if supplier_priority[index.to_s].to_s == "0"
        self.errors.add(:priority, "Please fill the priority " + (index + 1).to_s)
      end
    end
  end

  def self.synch_suppliers_now
    #check offset
    flag =false
    offset = OffsetApi.get_offset("Supplier")
    unless offset.nil?
      begin
        res= OffsetApi.connect_with_offset("suppliers",API_LIMIT,offset)
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
          save_supplier = Supplier.save_suppliers_from_api(result)
          if save_supplier != true
             ActiveRecord::Rollback
             return flag = save_supplier
          end
          if  OffsetApi.update_po_api_offset("Supplier",result['count'])
             flag = true
          else
            return flag = false
          end
        return flag=true
        end
      rescue => e
        ActiveRecord::Rollback
          flag=false
          return flag
      end
    end
    return flag
  end

  def self.save_a_supplier_from_api(params)
    flag = false

    params['data'].each do |s|
      supplier = Supplier.where(:code=>s['cre_accountcode'].squish)
      if supplier.blank?
        group = Group.where(:code => "#{s['cr_supplier_grp']}".squish).first
        if group.blank?
          #get group from api and save it
          group = Supplier.get_and_save_suppliers_group_from_api(s['cr_supplier_grp'])
          unless group.instance_of? Group
            ActiveRecord::Rollback
            return flag = group
          end
        end

        new_supplier = group.suppliers.new(
            :name => s['cr_shortname'].present?? s['cr_shortname'].squish : "-",
            :code => s['cre_accountcode'].squish,
            :level=> 1
            )
        new_supplier.service_level_total = 0
        if new_supplier.save
          save_address = new_supplier.get_and_save_address_from_api
          puts "Create Supplier - #{new_supplier.code}"
          if save_address != true
            return flag = save_address
          else
            flag = new_supplier
          end
        else
          return flag = false
        end
      else
        return flag = true
      end
    end
    return flag
  end

  def get_and_save_address_from_api
    flag = false
    res = OffsetApi.connect_with_query("namaster","accountcode",self.code)
    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)
    return flag = true if result['data'].blank?
    supplier_addr = Address.set_and_save_supplier_addr(result,self)

    if supplier_addr
      return flag = true
    else
      return flag
    end
  end

  def callback_update_supplier_from_api
    res = OffsetApi.connect_with_query("suppliers", "cre_accountcode", "#{self.code}")
    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)
    if result['data'].blank?
      return flag = -1
    else
      supplier_update = self.update_a_supplier_from_api(result)
      if supplier_update
        flag = true
      else
        flag = false
      end
    end
    return flag
  end

  def update_a_supplier_from_api(params)
    flag = false
    begin
      ActiveRecord::Base.transaction do
        params['data'].each do |supp|
          if self.code.downcase == supp['cre_accountcode'].downcase.squish
            self.name = supp['cr_shortname'].blank? ? '' : supp['cr_shortname'].squish
            self.code = supp['cre_accountcode'].squish
            if self.save
              flag = true
            else
              flag = false
            end
          end
        end

        if flag
          if self.addresses
            self.addresses.destroy_all
            address = get_and_save_address_from_api
            if address
              flag = true
            else
              flag == false
            end
          else
            flag = false
          end
        else
          flag = false
        end
      end
      return flag
    rescue => e
        return flag
        ActiveRecord::Rollback
    end
  end

  def self.get_data_supplier_by_code(code)
    supplier = Supplier.find_by_code(code)
    return supplier if supplier
  end

  def self.synch_supplier_based_on_group_code(group_code)
    begin
      res = OffsetApi.connect_with_query("suppliers", "cr_supplier_grp", "#{group_code}")
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
      supplier_group_update = self.update_supplier_for_new_group(result)
      if supplier_group_update == -1
        flag = -1
      else
        if supplier_group_update == true
          flag = true
        else
          flag = false
        end
      end
    end
    return flag
  end

  def self.update_supplier_for_new_group(params)
    flag = false
    unless params['data'].blank?
      params['data'].each do |p|
        group = Group.where(:code => "#{p['cr_supplier_grp'].squish}", :group_type => "Supplier").first
        if group
          unless group.suppliers.collect(&:code).include?("#{p['cre_accountcode'].squish}")
            existed_supplier = Supplier.where(:code => "#{p['cre_accountcode'].squish}").first
            if existed_supplier.blank?
              #========== save new or existed supplier for a group ==============
              new_supplier = group.suppliers.new
              new_supplier.name = p['cr_shortname'].blank? ? '' : p['cr_shortname'].squish
              new_supplier.code = p['cre_accountcode'].squish
              new_supplier.last_purchase = p['last_purchase']
              new_supplier.last_payment = p['last_payment']
              new_supplier.account_opened = p['cr_date_created']
              new_supplier.service_level_total = 0
              if new_supplier.save
                flag = true
                save_address = new_supplier.get_and_save_address_from_api
                puts "Create Supplier - #{new_supplier.code}"
                if save_address != true
                  return flag = save_address
                else
                  return flag = new_supplier
                end
              else
                return flag = false
              end
            else
              unless existed_supplier.group_id == group.id
                existed_supplier.group_id = group.id
                existed_supplier.last_purchase = p['last_purchase']
                existed_supplier.last_payment = p['last_payment']
                existed_supplier.account_opened = p['cr_date_created']
                return flag = existed_supplier.save
              else
                existed_supplier.last_purchase = p['last_purchase']
                existed_supplier.last_payment = p['last_payment']
                existed_supplier.account_opened = p['cr_date_created']
                existed_supplier.save
                flag = -1 #mengembalikan status jika tidak ada data yang di update
              end
            end
            #======================================================
          else
            flag = -1 #mengembalikan status jika tidak ada data yang di update
          end
        end
      end
    else
      return flag = false
    end
    return flag
  end
end
