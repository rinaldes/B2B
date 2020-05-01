class InvHistory < ActiveRecord::Base
  attr_accessible :f_name, :old_val, :new_val, :purchase_order_id, :rev
end
