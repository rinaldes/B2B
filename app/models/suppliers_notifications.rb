class SuppliersNotifications < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :notification
  attr_accessible :state
  attr_protected :supplier_id, :notification_id

  state_machine initial: :unread do
    state :unread, value: 0
    state :read, value: 1

    event :read do
      transition :unread => :read
    end
  end

  def self.search(options, supplier)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'title'
          supplier.suppliers_notifications.includes(:notification).where("notifications.title ilike ?", "%#{options[:search][:detail]}%")
        end
        else
          supplier.suppliers_notifications.includes(:notification).where("notifications.title ilike ?", "%#{options[:search][:detail]}%")
      end
      else
        scoped
    end
  end

  def self.save_notif(notification_id)
   suppliers = Supplier.find(:all, select: 'id')
   suppliers.each do |supplier|
    ns = SuppliersNotifications.new
    ns.supplier_id = supplier.id
    ns.notification_id = notification_id
    ns.save
   end
  end
end
