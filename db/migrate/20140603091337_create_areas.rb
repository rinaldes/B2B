class CreateAreas < ActiveRecord::Migration
  def change
    create_table :areas do |t|
      t.string :area_name
      t.string :area_code
      t.timestamps
    end
  end
end
