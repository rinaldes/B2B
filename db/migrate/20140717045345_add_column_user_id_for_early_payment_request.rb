class AddColumnUserIdForEarlyPaymentRequest < ActiveRecord::Migration
  def up
    add_column :early_payment_requests, :user_id, :integer
  end

  def down
    remove_column :early_payment_requests, :user_id
  end
end
