class CreateTypeOfUsers < ActiveRecord::Migration
  def change
    create_table :type_of_users do |t|
      t.integer :parent_id
      t.string :description
      t.timestamps
    end
  end
end
