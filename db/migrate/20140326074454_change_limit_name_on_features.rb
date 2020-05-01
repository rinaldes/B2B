class ChangeLimitNameOnFeatures < ActiveRecord::Migration
  def up
  	change_column :features, :name, :string, :limit => 255
  end

  def down
  end
end
