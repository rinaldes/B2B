class CreateOffsetApis < ActiveRecord::Migration
  def change
    create_table :offset_apis do |t|
      t.string :api_type, :limit=>50
      t.integer :offset
      t.timestamps
    end
  end
end
