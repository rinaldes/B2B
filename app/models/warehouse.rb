class Warehouse < ActiveRecord::Base
   has_many :warehouses_products
   has_many :products, through: :warehouses_products
   has_many :purchase_orders
   has_many :level_limits
   has_many :users
   has_many :payments
   has_one :emaiil_notification
   belongs_to :area
   has_many :addresses, as: :location
   has_many :payment_vouchers
   has_many :debit_notes
   belongs_to :group, :conditions => ['groups.group_type = ?', 'Warehouse']
   attr_accessible :warehouse_code, :warehouse_name, :warehouse_area, :warehouse_region
   attr_protected :area_id, :group_id
   after_save :save_level_limit

   paginates_per PER_PAGE
   max_paginates_per 100
   def self.search(options)
   	unless options[:search].blank?
   		scoped
   	else
   		scoped
   	end
   end

   def save_level_limit
    unless self.level_limits.present?
      level_limit = LevelLimit.new(:level_type=>"#{GRN}", :limit_date => 0)
      level_limit.warehouse_id = self.id
      level_limit.save

      level_limit = LevelLimit.new(:level_type=>"#{GRPC}", :limit_date => 0)
      level_limit.warehouse_id = self.id
      level_limit.save

      level_limit = LevelLimit.new(:level_type=>"#{GRTN}", :limit_date => 0)
      level_limit.warehouse_id = self.id
      level_limit.save
    end
  end

  #untuk save warehouse beserta areas
  def self.save_warehouse_and_areas_from_api(params)
    areas = Area.order("id ASC")
    warehouses = self.order("id ASC")

    params["data"].each do |p|
      if p["sys_tbl_type"].downcase == "rc"
        unless areas.pluck(:area_code).include?("#{p["sys_tbl_code"]}")
          area = Area.new
          area.area_code = p["sys_tbl_code"]
          area.area_name = p["sys_description"]
          area.save
        end
      elsif p["sys_tbl_type"].downcase == "wh"
        unless warehouses.pluck(:warehouse_code).include?("#{p["sys_tbl_code"]}")
          warehouse = Warehouse.new
          warehouse.warehouse_code = p["sys_tbl_code"]
          warehouse.warehouse_name = p["sys_description"]
          warehouse.save
        end
      end
    end
  end

  def self.synch_warehouses_now
    #check offset
    flag =false
    offset =  OffsetApi.get_offset("Warehouse")
    unless offset.nil?
      begin
        res= OffsetApi.connect_with_offset_systbl('systable',API_LIMIT,offset,'WH')
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
          saved_warehouses = Warehouse.save_warehouses_from_api(result)
          return flag = saved_warehouses if saved_warehouses  != true
          if  OffsetApi.update_po_api_offset("Warehouse",result['count'])
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

  def self.save_warehouses_from_api(params)
    flag = false
    blank_flag = true
    begin
        ActiveRecord::Base.transaction do
          params['data'].each do |wh|
            warehouse  = Warehouse.where(:warehouse_code=>wh['sys_tbl_code'].squish).first
            if warehouse.blank? && wh['sys_tbl_type'].downcase.squish == "wh"
              code_group = wh['sys_tbl_alpha_1'][4..7].squish
              unless code_group.mb_chars.length < 3
                group = Group.where(:code => "#{code_group}").first
                if group.blank?
                #get group from api and save it
                  group = Warehouse.get_and_save_warehouses_group_from_api(code_group)
                end
                unless group == -2
                  warehouse = group.warehouses.where(:warehouse_code =>"#{wh['sys_tbl_code']}".squish).first
                end
              else
                group = ""
              end
              unless group.blank?
                if warehouse.blank?
                  new_whse = Warehouse.new(
                  :warehouse_name=> wh['sys_description'],
                  :warehouse_code=> wh['sys_tbl_code'].squish
                  )
                  new_whse.group_id = group.id
                  return flag = false if !new_whse.save
                  save_address = new_whse.get_and_save_a_warehouse_address_from_api
                  if save_address != true
                    return flag = save_address
                  else
                    flag = true
                  end
                  blank_flag = false
                  else
                  if blank_flag
                    return flag = -1
                  end
                  flag = true
                end
              else
                if warehouse.blank?
                  new_whse = Warehouse.new(
                  :warehouse_name=> wh['sys_description'],
                  :warehouse_code=> wh['sys_tbl_code'].squish
                  )
                  return flag = false if !new_whse.save
                  save_address = new_whse.get_and_save_a_warehouse_address_from_api
                  if save_address != true
                    return flag = save_address
                  else
                    flag = true
                  end
                  blank_flag = false
                  else
                  if blank_flag
                    return flag = -1
                  end
                  flag = true
                end
              end
            end
          end
          if blank_flag
            return flag = -1
          end
        end
        rescue => e
        ActiveRecord::Rollback
          flag=false
          return flag
      end
    return flag
  end

  def self.save_a_warehouse_from_api(params)
    flag = false
    params['data'].each do |wh|
      new_whse = Warehouse.new(
      :warehouse_name=> wh['sys_description'],
      :warehouse_code=> wh['sys_tbl_code'].squish
      )
      if new_whse.save
        save_address = new_whse.get_and_save_a_warehouse_address_from_api
        if save_address != true
          return flag = save_address
        else
          flag = new_whse
        end
      else
        return flag = false
      end
    end
    return flag
  end

  def self.get_and_save_warehouses_group_from_api(group_code)
    flag = false
    address = "systable"
    res = OffsetApi.connect_without_offset_systbl(address, group_code, "GW")
    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)
    return flag = -2 if result['data'].blank?
    warehouse_group = Group.set_and_save_a_warehouse_group(result)
    if warehouse_group.instance_of? Group
      flag = warehouse_group
    end
    return flag
  end

  def get_and_save_a_warehouse_address_from_api
    flag = false
    address = "namaster"
    res = OffsetApi.connect_with_query(address,"accountcode",self.warehouse_code.squish)
    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)
    return flag = true if result['data'].blank?
    #save address warehouse here
    whse_addr = Address.set_and_save_whse_addr(result,self)
    if whse_addr
      return flag = true
    else
      return flag
    end
  end

  def callback_api_warehouse_based_on_code
    res = OffsetApi.connect_without_offset_systbl("systable","#{self.warehouse_code}","WH")
    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)
    if result['data'].blank?
      return flag = -1
    else
      warehouse_update = self.update_a_warehouse_from_api(result)
      if warehouse_update
        flag = true
      else
        flag = false
      end
    end
    return flag
  end

  def update_a_warehouse_from_api(params)
    flag = false
    begin
      ActiveRecord::Base.transaction do
        params['data'].each do |wh|
          unless wh['sys_tbl_type'].blank?
            if self.warehouse_code.downcase == wh['sys_tbl_code'].downcase.squish && wh['sys_tbl_type'].downcase.squish == "wh"
              self.warehouse_name = wh['sys_description'].blank? ? '' : wh['sys_description'].squish
              self.warehouse_code = wh['sys_tbl_code'].squish
              if self.save
                flag = true
              else
                flag = false
              end
            end
          else
            flag = false
          end
        end
      end
      return flag
    rescue => e
        return flag
        ActiveRecord::Rollback
    end
  end

  def self.synch_warehouse_based_on_group_code(group_code)
    whcls = "sys_tbl_type = 'WH' AND sys_tbl_alpha_1 LIKE '%#{group_code}%'"
    begin
      res = OffsetApi.connect_api_with_query("systable", whcls)
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
      whse_group_update = self.update_warehouse_for_new_group(result)
      if whse_group_update == -1
        flag = -1
      else
        if whse_group_update == true
          flag = true
        else
          flag = false
        end
      end
    end
    return flag
  end

  def self.update_warehouse_for_new_group(params)
    flag = false
    unless params['data'].blank?
      params['data'].each do |p|
        g_code = p['sys_tbl_alpha_1'].squish
        group = Group.where("group_type = ? AND code = ?", 'Warehouse', g_code).first
        if group
          unless group.warehouses.collect(&:warehouse_code).include?("#{p['sys_tbl_code'].squish}")
            existed_warehouse = Warehouse.where(:warehouse_code => "#{p['sys_tbl_code'].squish}").first
            if existed_warehouse.blank?
              #========== save new or existed warehouse for a group ==============
              new_warehouse = group.warehouses.new
              new_warehouse.warehouse_name = p['sys_description'].blank? ? '' : p['sys_description'].squish
              new_warehouse.warehouse_code = p['sys_tbl_code'].squish
              if new_warehouse.save
                flag = true
                save_address = new_warehouse.get_and_save_address_from_api
                puts "Create warehouse - #{new_warehouse.warehouse_code}"
                if save_address != true
                  return flag = save_address
                else
                  return flag = new_warehouse
                end
              else
                return flag = false
              end
            else
              unless existed_warehouse.group_id == group.id
                existed_warehouse.group_id = group.id
                return flag = existed_warehouse.save
              else
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

  def get_and_save_address_from_api
    flag = false
    res = OffsetApi.connect_with_query("namaster","accountcode", self.warehouse_code)
    unless res.is_a?(Net::HTTPSuccess)
      return flag = OffsetApi.eval_net_http(res)
    end
    result = JSON.parse(res.body)
    return flag = true if result['data'].blank?
    whse_addr = Address.set_and_save_whse_addr(result,self)

    if whse_addr
      return flag = true
    else
      return flag
    end
  end

  def self.get_data_warehouse_by_code(code)
    warehouse = Warehouse.find_by_warehouse_code(code)
    return warehouse if warehouse
  end
end
