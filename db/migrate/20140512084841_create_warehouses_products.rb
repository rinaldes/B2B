class CreateWarehousesProducts < ActiveRecord::Migration
  def change
  	create_table :warehouses_products do |t|
  		t.integer :warehouse_id
  		t.integer :product_id

  		t.timestamps
  	end
  end
end
