class CreateStockSerialLinks < ActiveRecord::Migration
  def change
    create_table :stock_serial_links do |t|
      t.string :serial_no
      t.string :stock_code
      t.string :serial_link_type
      t.string :serial_link_code
      t.string :link_suffix
      t.decimal :link_seq_no

      t.timestamps
    end
  end
end
