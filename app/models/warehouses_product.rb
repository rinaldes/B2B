class WarehousesProduct < ActiveRecord::Base
  belongs_to :product
  belongs_to :warehouse
  attr_protected :warehouse_id, :product_id
end
