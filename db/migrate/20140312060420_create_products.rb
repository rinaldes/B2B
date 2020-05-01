class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :code, limit:45
      t.string :name
      t.decimal :unit_price
      t.string :unit_qty, limit:45
      t.string :barcode, limit:45		
      t.timestamps
    end
  end
end
