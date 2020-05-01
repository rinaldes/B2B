class ChangeLengthColumnKeyFeature < ActiveRecord::Migration
  def up
    change_column :features, :key, :string, :length => 255
  end

  def down
  end
end
