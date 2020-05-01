class TypeOfUser < ActiveRecord::Base
  attr_accessible :description
  attr_protected :parent_id, :company_id

  belongs_to :parent, :class_name => "TypeOfUser"
  has_many :type_of_users, :foreign_key => "parent_id"
  has_many :users
  validates :description, :presence => {:message => "Sorry, Type can not an empty.", :allow_blank => false}, on: :create
  belongs_to :company

  paginates_per PER_PAGE
  max_paginates_per 100
  def self.search(options)
    unless options[:search].blank?
      where("description ilike ?", "%#{options[:search][:detail]}%")
    else
      scoped
    end
  end

  def group
    unless self.parent_id.blank?
      group = self.parent.description
    else
      group = "- No Group -"
    end
    return group
  end

  def customer?
    return true if self.description == "Customer"
  end

  def supplier?
    return true if self.description == "Supplier"
  end
end
