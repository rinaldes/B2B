class SupplierLevel < ActiveRecord::Base
  attr_accessible :level, :supplier_level_detail_id
  belongs_to :supplier_level_detail, :class_name => "SupplierLevelDetail"
  belongs_to :group, :class_name => "Group"
end
