class Notification < ActiveRecord::Base
  belongs_to :role
  belongs_to :type_of_user
  has_many :suppliers_notifications, :class_name => 'SuppliersNotifications'
  has_many :suppliers, :through => :suppliers_notifications

  has_many :group_notifications
  has_many :users, through: :group_notifications

  attr_accessible :title, :content, :notif_type, :role_id, :type_of_user_id, :valid_from, :valid_until

  validates_length_of :title, :minimum => 5, :allow_blank => false
  validates_length_of :content, :minimum => 10,  :tokenizer => lambda { |str| ActionController::Base.helpers.strip_tags(str) }

  def self.search(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'title'
          #where("title ilike ?", "%#{options[:search][:detail]}%")
          supplier.suppliers_notifications.includes(:notification).where("notifications.title ilike ?", "%#{options[:search][:detail]}%")
        when "type"
          supplier.suppliers_notifications.includes(:notification).where("notifications.type ilike ?", "%#{options[:search][:detail]}%")
        end
      else
        supplier.suppliers_notifications.includes(:notification).where("notifications.title ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      scoped
    end
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

  def self.create_notif_po(object)
    new_notif = Notification.new()
    if object.instance_of?PurchaseOrder
      case po.order_type.to_s
      when "#{PO}"
        set_notif_po
      when "#{GRN}"
        set_notif_grn
      end
    elsif object.instance_of?ReturnedProcess
      set_notif_grtn(object)
    else
      return new_notif = false
    end
    new_notif = false if !new_notif.save
    return new_notif
  end

  def set_notif_po(po)
    self.title = "New Purchase Order from //ware"
    self.content = ""
    self.notif_type
  end

  def set_notif_grn(grn)
  end

  def set_notif_grtn(retur)
  end

  def save_notif params
    group_notifications.delete_all
    if notif_type == 'User'
      params[:users].each{|user|
        group_notifications.create receipant_id: user
      }
    elsif notif_type == 'Role'
      params[:roles].each{|role|
        Role.find(role).users.each{|user|
          group_notifications.create receipant_id: user.id
        }
      }
    end
  end
end