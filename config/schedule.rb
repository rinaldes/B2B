# set :environment, :development

require File.expand_path('../application', __FILE__)
B2bSystem::Application.initialize!
set :output, {:error => 'cron_error.log', :standard => 'cron_status.log'}

every 1.days do
end

service = ServiceSchedulerApi.first

unless service.nil?
  type_time = service.type_time
  set_time = service.set_time
  if type_time == 'H'
    every set_time.hours do
      runner "Warehouse.delay(priority: 1, run_at: 1.minutes.from_now).synch_warehouses_now"
      runner "Supplier.delay(priority: 2, run_at: 1.minutes.from_now).synch_suppliers_now"
      runner "Product.delay(priority: 3, run_at: 1.minutes.from_now).synch_products_periodically"
      runner "PurchaseOrder.delay(priority: 4, run_at: 1.minutes.from_now).synch_po_now"
      runner "PurchaseOrder.delay(priority: 5, run_at: 1.minutes.from_now).synch_grn_now"
      runner "PurchaseOrder.delay(priority: 6, run_at: 1.minutes.from_now).synch_retur_now"
      runner "DebitNote.delay(priority: 7, run_at: 1.minutes.from_now).synch_debit_note_periodically"
    end
  elsif type_time == 'M'
    every set_time.minutes do
      runner "Warehouse.delay(priority: 1, run_at: 1.minutes.from_now).synch_warehouses_now"
      runner "Supplier.delay(priority: 2, run_at: 1.minutes.from_now).synch_suppliers_now"
      runner "Product.delay(priority: 3, run_at: 1.minutes.from_now).synch_products_periodically"
      runner "PurchaseOrder.delay(priority: 4, run_at: 1.minutes.from_now).synch_po_now"
      runner "PurchaseOrder.delay(priority: 5, run_at: 1.minutes.from_now).synch_grn_now"
      runner "PurchaseOrder.delay(priority: 6, run_at: 1.minutes.from_now).synch_retur_now"
      runner "DebitNote.delay(priority: 7, run_at: 1.minutes.from_now).synch_debit_note_periodically"
    end
  end
else
  every 1.hours do
    runner "PurchaseOrder.delay(priority: 4, run_at: 1.minutes.from_now).synch_po_now"
    runner "PurchaseOrder.delay(priority: 5, run_at: 1.minutes.from_now).synch_grn_now"
    runner "PurchaseOrder.delay(priority: 6, run_at: 1.minutes.from_now).synch_retur_now"
    runner "DebitNote.delay(priority: 7, run_at: 1.minutes.from_now).synch_debit_note_periodically"
  end
end

every 1.days, :at => '00:00 am' do
  runner "ReturnedProcess.send_grtn"
  runner "PurchaseOrder.send_grn"
  runner "PurchaseOrder.send_grpc"
end

every 1.days, :at => '00:01 am' do
  runner "OffsetApi.('Product', true)"
  runner "OffsetApi.('Purchase Order', true)"
  runner "OffsetApi.('Supplier', true)"
  runner "OffsetApi.('Warehouse', true)"
end
