class CreateHelps < ActiveRecord::Migration
  def change
    create_table :helps do |t|
      t.text :description
      t.string :attachment
      t.string :page

      t.timestamps
    end
  end
end
