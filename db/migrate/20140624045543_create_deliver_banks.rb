class CreateDeliverBanks < ActiveRecord::Migration
  def change
    create_table :deliver_banks do |t|
      t.string :receive_bank_name
      t.string :receive_bank_rek
      t.string :from_bank_name
      t.string :from_bank_rek
      t.integer :early_payment_request_id
      t.integer :user_id
      t.timestamps
    end
  end
end
