class Group < ActiveRecord::Base
  has_many :suppliers
  has_many :warehouses
  has_many :supplier_levels, :primary_key => "level", :foreign_key => "level", :source => "SupplierLevelDetail"
  has_many :supplier_level_details, through: :supplier_levels

  attr_accessible :name
  scope :suppliers_groups, lambda {|id,type| {:conditions=> {:id=>id, :group_type => type}}}
  scope :warehouses_groups, lambda {|id,type| {:conditions=> {:id=>id, :group_type => type}}}

  #searching untuk group supplier
  def self.search(options)
  	unless options[:search].blank?
      if options[:search][:group_code].present?
        where("code ilike ?","%#{options[:search][:group_code]}%")
      elsif options[:search][:group_name].present?
        where("name ilike ?","%#{options[:search][:group_name]}%")
      elsif options[:search][:level].present?
        where("level = ?","#{options[:search][:level].to_i}")
      elsif options[:search][:last_update].present?
        where("updated_at::text like '%#{options[:search][:last_update]}%'")
      else
        where("code ilike ?","%#{options[:search][:group_code]}%")
      end
    else
      scoped
    end
  end

  #desc: untuk set dan save group supplier
  def self.set_and_save_a_supplier_group(params)
  	flag =false
    params['data'].each do |g|
      group = Group.new
      group.name = "#{g['sys_description']}".squish
      group.code = "#{g['sys_tbl_code']}".squish
      group.group_type = "Supplier"
      group.level = 1
      if group.save
        flag = group
      end
    end
    return flag
  end

  #desc: untuk set dan save group warehouse
  def self.set_and_save_a_warehouse_group(params)
    flag =false
    params['data'].each do |g|
      group = Group.new
      group.name = "#{g['sys_description']}".squish
      group.code = "#{g['sys_tbl_code']}".squish
      group.group_type = "Warehouse"
      if group.save
        flag = group
      end
    end
    return flag
  end

  def export_to_xls
    book = Spreadsheet::Workbook.new
    column_bold = Spreadsheet::Format.new({ :weight => :bold, :pattern => 1, :pattern_fg_color => :silver })
    details_column = Spreadsheet::Format.new({:pattern => 1, :pattern_fg_color => :yellow })
    details_header = Spreadsheet::Format.new({:weight => :bold, :pattern => 1, :pattern_fg_color => :blue, :color => :white })
    left_header_template = ["Code","Name","Last Update"]
    middle_template = ["Code","Name","Last Update"]

    sheet1 = book.create_worksheet :name => "Warehouse Group"
    index = 0

    # HEADER
    3.times do |t|
      # ============  LEFT HEADER
      #column 0
      sheet1.row(t).default_format = column_bold
      sheet1[t, 0] = left_header_template[t]
      index += 1
    end

    # VALUE GENERAL
    sheet1[0, 1] = self.code
    sheet1[1, 1] = self.name
    sheet1[2, 1] = self.updated_at
    # END HEADER

    # BAGIAN DETAIL HEADER
    sheet1[3, 0] = 'Group Details'
    sheet1.row(3).default_format = details_header

    3.times do |t|
      sheet1[4, t] = middle_template[t]
      sheet1.row(4).default_format = column_bold
    end
    index += 2
    # END DETAIL HEADER

    # DETAIL ITEM
    self.warehouses.each_with_index do |ware, i|
      sheet1.row(i+index).default_format = details_column
      sheet1[i+index, 0] = ware.warehouse_code
      sheet1[i+index, 1] = ware.warehouse_name
      sheet1[i+index, 2] = ware.updated_at
    end

    path = "#{Rails.root}/public/purchase_order_xls/grtn_excel-file.xls"
    book.write path
    return {"path" => path}
  end

  #desc: set default ketika membuat user untuk customer maupun supplier
  def set_feature(type,user,params)
    if type == "supplier"
      #================== IF Level 1 & 2 ======================
      #================== ONLY GROUP SUPPLIER =================
      unless user.has_role? :superadmin
        if self.level == 1
          user.features.where("regulator = 'Dashboard'").collect{|f| f.users_features.collect{|uf| uf.delete } }
          user.features << Feature.where(:regulator => "Dashboard").where("name != 'Report invoice'")
          user.features << Feature.where(:regulator => "Dashboard").where("name != 'Report debit note'")
        elsif self.level == 2
          user.features << Feature.where(:regulator => "Dashboard").where("name = 'Report invoice'")
          user.features << Feature.where(:regulator => "Dashboard").where("name = 'Report debit note'")
        end
      end
    else
      #================== ONLY GROUP WAREHOUSE =================
      user.features << Feature.where(:regulator => 'Dashboard')
      user.features << Feature.where(:regulator => 'Supplier')
      user.features << Feature.where(:regulator => 'Product')
      user.features << Feature.where(:regulator => 'Warehouse')
    end

    #fungsi dibawah dibuat karena jika disatukan dengan diatas tidak valid, aneh pisan
    if type == "supplier"
      if self.level == 1
        user.features.where("regulator = 'Dashboard' AND name IN ('Report invoice','Report debit note')").collect{|f| f.users_features.collect{|uf| uf.delete } }
      elsif self.level == 2
        user.features << Feature.where(:regulator => "Dashboard").where("name = 'Report invoice'")
        user.features << Feature.where(:regulator => "Dashboard").where("name = 'Report debit note'")
      end
    end

    if params[:role_name] == "customer_admin_group"
      user.features << Feature.where(:regulator => 'User')
    elsif params[:role_name] == "supplier_admin_group"
      user.features << Feature.where(:regulator => 'User')
      user.features << Feature.where(:regulator => 'Supplier')
    end
  end
end
