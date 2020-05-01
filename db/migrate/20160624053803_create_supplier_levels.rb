class CreateSupplierLevels < ActiveRecord::Migration
  def change
    create_table :supplier_levels do |t|
      t.integer :level
      t.integer :supplier_level_detail_id;

      t.timestamps
    end

    create_table :supplier_level_details do |t|
      t.string :text;

      t.timestamps
    end
  end
end
