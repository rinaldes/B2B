class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.integer :supplier_id
      t.integer :warehouse_id
      t.decimal :total, :precision=> 12, :scale=>2
      t.integer :state
      t.timestamps
    end
  end
end
