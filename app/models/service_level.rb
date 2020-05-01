class ServiceLevel < ActiveRecord::Base
  attr_accessible :sl_qty, :sl_line, :sl_time, :sl_code
  attr_protected :supplier_id

  attr_accessor :one_hundred
  has_many :suppliers

  validates :sl_code, presence: {:message=> "Sorry code have to be filled", allow_blank: false, allow_nil:false}, uniqueness: {:message=> "The code you have entered already exist"}
  validates :sl_time, presence: {:message=>"Sorry time have to be filled", allow_blank: false, allow_nil:false}, numericality: { only_integer: true, :message=>"must be integer" }
  validates :sl_line, presence: {:message=>"Sorry line have to be filled", allow_blank: false, allow_nil:false}, numericality: { only_integer: true, :message=>"must be integer" }
  validates :sl_qty, presence: {:message=>"Sorry quantity have to be filled", allow_blank: false, allow_nil:false}, numericality: { only_integer: true, :message=>"must be integer" }
  validate :must_one_hundred

  def self.search(options)
  	unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'code'
          where("sl_code ilike ?", "%#{options[:search][:detail]}%")
        end
      else
         where("sl_code ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      scoped
    end
  end

  def must_one_hundred
      a=sl_line + sl_time + sl_qty
      if a != 100
      	errors.add(:one_hundred, "sum of service level quantity, time and line must be exactly 100 (one hundred)")
        errors.add(:sl_line, "")
        errors.add(:sl_qty, "")
        errors.add(:sl_time, "")
      end

  end
end
