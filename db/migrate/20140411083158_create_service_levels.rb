class CreateServiceLevels < ActiveRecord::Migration
  def change
    create_table :service_levels do |t|
      t.integer :supplier_id
      t.string :sl_code
      t.float :sl_qty
      t.float :sl_line
      t.float :sl_time
      t.timestamps
    end
  end
end
