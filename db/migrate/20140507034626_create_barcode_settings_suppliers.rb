class CreateBarcodeSettingsSuppliers < ActiveRecord::Migration
  def change
    create_table :barcode_settings_suppliers do |t|
      t.integer :number
      t.integer :priority
      t.integer :supplier_id
      t.text :description

      t.timestamps
    end
  end
end
