class CreateEmailContents < ActiveRecord::Migration
  def change
    create_table :email_contents do |t|
      t.text :content
      t.string :status
      t.timestamps
    end
  end
end
