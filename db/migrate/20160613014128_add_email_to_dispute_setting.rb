class AddEmailToDisputeSetting < ActiveRecord::Migration
  def change
    add_column :dispute_settings, :email_content, :text
  end
end
