class DeliverBank < ActiveRecord::Base
  attr_accessible :receive_bank_name, :receive_bank_rek, :from_bank_name, :from_bank_rek
  attr_protected :early_payment_request_id, :user_id
  belongs_to :early_payment_request
  belongs_to :user
  validates :receive_bank_name, :presence => {:message => "Please fill bank name receive", :allow_blank => false}
  validates :receive_bank_rek, :presence => {:message => "Please fill account receive", :allow_blank => false}
  validates :from_bank_name, :presence => {:message => "Please fill bank name deliver", :allow_blank => false}
  validates :from_bank_rek, :presence => {:message => "Please fill account bank deliver ", :allow_blank => false}

  def save_detail_bank(epr, options, user)
    flag = false
    begin
      ActiveRecord::Base.transaction do
        self.receive_bank_name = options[:deliver_bank][:receive_bank_name]
        self.receive_bank_rek = options[:deliver_bank][:receive_bank_rek]
        self.from_bank_name = options[:deliver_bank][:from_bank_name]
        self.from_bank_rek = options[:deliver_bank][:from_bank_rek]
        self.user_id = user.id
        new_epr = epr.update_status_early_payment_request("accept", user)
        if new_epr
          self.early_payment_request_id = new_epr.id
          if self.save
            flag = true
          end
        else
          flag = false
        end
      end
    rescue => e
      flag = false
      ActiveRecord::Rollback
    end
    return flag
  end
end
