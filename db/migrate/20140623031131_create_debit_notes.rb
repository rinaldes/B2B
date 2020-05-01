class CreateDebitNotes < ActiveRecord::Migration
  def change
    create_table :debit_notes do |t|
      t.integer :supplier_id
      t.integer :warehouse_id
      t.decimal :grand_total
      t.integer :state
      t.timestamps
    end
  end
end
