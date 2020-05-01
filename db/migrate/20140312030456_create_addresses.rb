class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.text :name
      t.references :location, polymorphic: true	
      t.timestamps
    end
  end
end
