class DisputeSetting < ActiveRecord::Base
  attr_accessible :max_count, :transaction_type, :time_type, :email_content, :max_round
  validates :max_count, presence: {:message => "Sorry, Max Count can't be blank.", on: :create}
  validates :transaction_type, presence: {:message => "Sorry, Transaction Type can't be blank.", on: :create}, uniqueness: {:message => 'Sorry, Transaction Type has been existed.', on: :create}

  def self.search(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field]
        when 'Transaction Type'
          #where("transaction_type ilike ?", "%#{options[:search][:detail]}%")
          where("transaction_type = 'GRN'")
          when 'Max Count'
            #where("max_count ilike ?", "%#{options[:search][:detail]}%")
            where("max_count = 1")
            when 'Time Type'
                where("time_type ilike ?","%#{options[:search][:detail]}%")
        end
      else
         #where("transaction_type ilike ?", "%#{options[:search][:detail]}%")
         where("transaction_type = 'GRN'")
      end
    else
      scoped
    end
  end
end
