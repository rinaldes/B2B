class CreateApiSettings < ActiveRecord::Migration
  def change
    create_table :api_settings do |t|
    	t.string :api
    	t.string :password
      t.timestamps
    end
  end
end
