class CreateSuppliers < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string :name, :limit=>45
      t.references :parent_id
      t.string :group, :limit=>45
      t.string :code, :limit=>45
      t.decimal :tax_of
      t.string :phone_number, :limit=>45
      t.string :level, :limit=>45	
      t.timestamps
    end
  end
end
