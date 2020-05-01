class CreateUsersFeatures < ActiveRecord::Migration
  def change
    create_table :users_features do |t|
      t.integer :user_id
      t.integer :feature_id
    end
  end
end
