class CreatePurchaseOrders < ActiveRecord::Migration
  def change
    create_table :purchase_orders do |t|
      t.string  :po_from, limit:45
      t.datetime :po_date
      t.datetime :planned_arrival
      t.string :po_number, limit:45
      t.string :asn_number, limit:45
      t.string :grn_number, limit:45
      t.string :grpc_number, limit:45
      t.string :invoice_number, limit:45
      t.string :order_type, limit:45
      t.string :order_status, limit:45
      t.string :invoice_barcode, limit:45
      t.references :supplier
      t.decimal :grand_total
      t.boolean :is_published, :default => false, :null => false
      t.text :po_remark
      t.string :tax_invoice_number,limit:45
      t.datetime :tax_invoice_date
      t.text :tax_invoice_remark
      t.string :status, limit:45
      t.timestamps
    end
  end
end
