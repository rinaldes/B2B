class SupplierLevelDetail < ActiveRecord::Base
  attr_accessible :text
  has_many :supplier_levels
  has_many :groups, :through => :supplier_levels
end
