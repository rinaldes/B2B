class Customer < ActiveRecord::Base
  has_many :addresses, as: :location
  attr_accessible :name, :email, :customer_type, :code
  has_many :users

  def self.save_customer_from_api(params)
    customers = self.order("id ASC")
    params["data"].each do |p|
      unless customers.pluck(:code).include?("#{p["accountcode"]}")
        customer = Customer.new
        customer.code = p["accountcode"]
        customer.name = p["shortname"]
        customer.save
      end
    end
  end
end
