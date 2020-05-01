class CreateWarehouses < ActiveRecord::Migration
  def change
    create_table :warehouses do |t|
      t.string :warehouse_code
      t.string :warehouse_name
      t.string :warehouse_area
      t.string :warehouse_region

      t.timestamps
    end
  end
end
