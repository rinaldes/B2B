class ExtraNote < ActiveRecord::Base
  attr_accessible :en_type, :text, :seq_no
  attr_protected :supplier_id
  belongs_to :supplier
end
