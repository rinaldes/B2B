class CreateFeatures < ActiveRecord::Migration
  def change
    create_table :features do |t|
      t.string :name, :limit =>45
      t.string :key, :limit => 45
      t.text :description
      t.timestamps
    end
  end
end
