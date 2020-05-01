class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :group_type
      t.string :name
      t.string :code
      t.timestamps
    end
  end
end
