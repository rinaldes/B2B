class EarlyPaymentRequest < ActiveRecord::Base
  attr_protected :purchase_order_id, :state
  attr_accessible :is_history
  belongs_to :purchase_order
  has_many :deliver_banks
  belongs_to :user
  has_many :user_logs, :as => :log

  state_machine :state, :initial => :pending do
    state :pending, :value => 0
    state :sent, :value => 1
    state :accepted, :value => 2
    state :rejected, :value => 3

    event :sending do
      transition :pending => :sent
    end

    event :accept do
      transition :sent => :accepted
    end

    event :reject do
      transition :sent => :rejected
    end

  end

  def save_activity
    ul = UserLog.new(:log_type => self.class.model_name, :event => self.state_name.to_s, :transaction_type => "#{EPR}" )
    ul.user_id = self.user_id
    ul.log_id = self.id
    ul.save
  end

  def self.search_early_payment_requests(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'invoice number'
          res = joins(:purchase_order).where("purchase_orders.invoice_number ilike ?", "%#{options[:search][:detail]}%")
        end
      end
    else
      res = scoped
    end
    return res
  end

  def update_status_early_payment_request(state_name, user)
    begin
      ActiveRecord::Base.transaction do
        new_epr = EarlyPaymentRequest.new
        new_epr.purchase_order_id = self.purchase_order_id
        new_epr.user_id = user.id
        if state_name.downcase == "send"
          PurchaseOrder.send_notifications(new_epr)
          new_epr.state = 1 if self.can_sending?
        elsif state_name.downcase == "accept"
          PurchaseOrder.send_notifications(new_epr)
          new_epr.state = 2 if self.can_accept?
        else
          PurchaseOrder.send_notifications(new_epr)
          new_epr.state = 3 if self.can_reject?
        end

        if new_epr.save && self.update_attributes(:is_history => true)
          return new_epr if new_epr.save_activity
        end
      end
    rescue => e
      return false
      ActiveRecord::Rollback
    end
  end
end
