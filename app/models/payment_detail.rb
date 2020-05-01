class PaymentDetail < ActiveRecord::Base
  belongs_to :payment
  belongs_to :payment_element, polymorphic: true
  attr_accessor :temp_type, :temp_code, :temp_detail_candidate, :temp_total
  attr_accessible :temp_code, :temp_type, :temp_detail_candidate, :temp_total

  def self.search(options)
    p_month,p_year, results = "","", self.order("created_at DESC")

    if options[:date].present?
      if options[:date][:month].present?
        p_month = options[:date][:month]
      end

      if options[:date][:year].present?
        p_year = options[:date][:year]
      end
    else
      p_month = Date.today.month
      p_year = Date.today.year
    end

    unless options[:search].blank?
      if options[:search][:supplier_code].present?
        supplier_id = Supplier.where(:code => options[:search][:supplier_code]).first
        results = where(:supplier_id => supplier_id)
      end
    end

    return results
  end

end
