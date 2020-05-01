class Addsomeclumnstofeatures < ActiveRecord::Migration
  def up
    add_column :features, :regulator, :string, :limit=>45
  end

  def down
  end
end
