if Rails.env.development? || Rails.env.staging? || Rails.env.production? || Rails.env.vmware?
  email_notification = EmailNotification.first
  unless email_notification
    title = ['new Good Receive note has been revisioned','Good Receive note has been disputed', 'Good Receive note has been accepted', 'Good Receive Price confirmation has been revisioned', 'Good Receive Price confirmation has been disputed', 'Good Receive Price confirmation has been accepted', 'Good Return note has been disputed', 'new Good Return note has been revisioned', 'Good Return note has been accepted', 'new Invoice has been created', 'new Early payment request has been pend','new Early payment request has been sent','new Early payment request has been accepted','new Early payment request has been rejected','new Payment voucher has been created','new Payment voucher has been pend', 'Payment voucher has been approved', 'Payment process has been created','Payment process has been accepted', 'Payment process has been rejected','DebitNote has been disputed', 'DebitNote has been revisioned', 'DebitNote has been accepted', 'DebitNote has been rejected']
    type = ['Good Receive note', 'Good Receive note', 'Good Receive note', 'Good Receive Price confirmation','Good Receive Price confirmation', 'Good Receive Price confirmation', 'Good Return note', 'Good Return note', 'Good Return note','Invoice','Early payment request','Early payment request','Early payment request','Early payment request', 'Payment voucher','Payment voucher','Payment voucher', 'Payment Process','Payment Process','Payment Process', 'DebitNote', 'DebitNote', 'DebitNote', 'DebitNote']
    process = ['Good Receive note disputed', 'Good Receive note revised', 'Good Receive note accepted', 'Good Receive Price disputed','Good Receive Price revised', 'Good Receive Price accepted', 'Good Return note disputed', 'Good Return note revised', 'Good Return note accepted', 'Invoice created','Early payment request pend','Early payment request sent','Early payment request accepted','Early payment request rejected', 'Payment voucher created', 'Payment voucher pending', 'Payment voucher approved', 'Payment process created', 'Payment process accepted','Payment process rejected', 'DebitNote disputed', 'DebitNote revised', 'DebitNote accepted', 'DebitNote rejected']
    puts "Create email_notifications :"
    puts "========================="
    24.times do |i|
      email_notification = EmailNotification.new(
        subject: "Notification #{process[i]}",
        description: "<p>This is notification from B2B portal,&nbsp;</p>
        <p>we want to inform you that a #{title[i]} in B2B. Please check your #{type[i]} index for more information.</p>
        <p>If you have any problem in this process, please feel free for contact your system administrator.</p>
        <p>&nbsp;</p>
        <p>Thank you,</p>",
        email_type: i + 1
        )
      case i
        when 0
          email_notification.type_po = "#{GRN}"
          email_notification.state = "dispute"
        when 1
          email_notification.type_po = "#{GRN}"
          email_notification.state = "rev"
        when 2
          email_notification.type_po = "#{GRN}"
          email_notification.state = "accepted"
        when 3
          email_notification.type_po = "#{GRPC}"
          email_notification.state = "dispute"
        when 4
          email_notification.type_po = "#{GRPC}"
          email_notification.state = "rev"
        when 5
          email_notification.type_po = "#{GRPC}"
          email_notification.state = "accepted"
        when 6
          email_notification.type_po = "#{GRTN}"
          email_notification.state = "disputed"
        when 7
          email_notification.type_po = "#{GRTN}"
          email_notification.state = "rev"
        when 8
          email_notification.type_po = "#{GRTN}"
          email_notification.state = "accepted"
        when 9
          email_notification.type_po = "Invoice"
          email_notification.state = "new"
        when 10
          email_notification.type_po = "Early Payment Request"
          email_notification.state = "pending"
        when 11
          email_notification.type_po = "Early Payment Request"
          email_notification.state = "sent"
        when 12
          email_notification.type_po = "Early Payment Request"
          email_notification.state = "accepted"
        when 13
          email_notification.type_po = "Early Payment Request"
          email_notification.state = "rejected"
        when 14
          email_notification.type_po = "Payment Voucher"
          email_notification.state = "new"
        when 15
          email_notification.type_po = "Payment Voucher"
          email_notification.state = "pending"
        when 16
          email_notification.type_po = "Payment Voucher"
          email_notification.state = "approved"
        when 17
          email_notification.type_po = "Payment Process"
          email_notification.state = "pending"
        when 18
          email_notification.type_po = "Payment Process"
          email_notification.state = "approved"
        when 19
          email_notification.type_po = "Payment Process"
          email_notification.state = "rejected"
        when 20
          email_notification.type_po = "DebitNote"
          email_notification.state = "disputed"
        when 21
          email_notification.type_po = "DebitNote"
          email_notification.state = "revisioned"
        when 22
          email_notification.type_po = "DebitNote"
          email_notification.state = "accepted"
        when 23
          email_notification.type_po = "DebitNote"
          email_notification.state = "rejected"
      end
      if email_notification.save
        puts "Dummy email_notifications has been created."
      end

    end

    last_grpc_email = EmailNotification.where("type_po='Goods Receive Price Confirmations'").last
    EmailNotification.create state: 'unread', description: last_grpc_email.description.gsub('accepted', 'created'), subject: "Notification Good Receive Price created", email_type: 6,
      type_po: "Goods Receive Price Confirmations"
    EmailNotification.create state: 'nil', description: last_grpc_email.description.gsub('accepted', 'created'), subject: "Notification Good Receive Price created", email_type: 6,
      type_po: "Goods Receive Price Confirmations"
    EmailNotification.create state: 'nil', description: last_grpc_email.description.gsub('accepted', 'created'), subject: "Notification Good Receive Price created", email_type: 6,
      type_po: "Goods Receive Price Confirmations"
    EmailNotification.create state: 'pending', description: last_grpc_email.description.gsub('created', 'pending'), subject: "Notification Good Receive Price Pending", email_type: 6,
      type_po: "Goods Receive Price Confirmations"

    EmailNotification.create state: 'new',
      description: '<p>This is notification from B2B portal,&nbsp;</p><p>we want to inform you that a new Advance Shipment Notification has been created in B2B. Please check your Advance Shipment Notification index for more information.</p><p>If you have any problem in this process, please feel free for contact your system administrator.</p><p>&nbsp;</p><p>Thank you,</p>',
      subject: "Notification New Advance Shipment Notification", email_type: 1, type_po: "Advance Shipment Notifications"

    EmailNotification.create state: 'customer edited',
      description: '<p>This is notification from B2B portal,&nbsp;</p><p>we want to inform you that a new Advance Shipment Notification has been edited by customer in B2B. Please check your Advance Shipment Notification index for more information.</p><p>If you have any problem in this process, please feel free for contact your system administrator.</p><p>&nbsp;</p><p>Thank you,</p>',
      subject: "Notification New Advance Shipment Notification", email_type: 1, type_po: "Advance Shipment Notifications"

    EmailNotification.create state: 'supplier edited',
      description: '<p>This is notification from B2B portal,&nbsp;</p><p>we want to inform you that a new Advance Shipment Notification has been edited by supplier in B2B. Please check your Advance Shipment Notification index for more information.</p><p>If you have any problem in this process, please feel free for contact your system administrator.</p><p>&nbsp;</p><p>Thank you,</p>',
      subject: "Notification New Advance Shipment Notification", email_type: 1, type_po: "Advance Shipment Notifications"

    EmailNotification.create state: 'accepted',
      description: '<p>This is notification from B2B portal,&nbsp;</p><p>we want to inform you that a new Advance Shipment Notification has been accepted in B2B. Please check your Advance Shipment Notification index for more information.</p><p>If you have any problem in this process, please feel free for contact your system administrator.</p><p>&nbsp;</p><p>Thank you,</p>',
      subject: "Notification New Advance Shipment Notification", email_type: 1, type_po: "Advance Shipment Notifications"

    EmailNotification.create state: 'printed',
      description: '<p>This is notification from B2B portal,&nbsp;</p><p>we want to inform you that a new Invoice has been printed in B2B. Please check your Invoice index for more information.</p><p>If you have any problem in this process, please feel free for contact your system administrator.</p><p>&nbsp;</p><p>Thank you,</p>',
      subject: "Notification Invoice Printed", email_type: 1, type_po: "Invoice"

    EmailNotification.create state: 'incomplete',
      description: '<p>This is notification from B2B portal,&nbsp;</p><p>we want to inform you that a new Invoice has been incompleted in B2B. Please check your Invoice index for more information.</p><p>If you have any problem in this process, please feel free for contact your system administrator.</p><p>&nbsp;</p><p>Thank you,</p>',
      subject: "Notification Invoice Incompleted", email_type: 1, type_po: "Invoice"

    EmailNotification.create state: 'completed',
      description: '<p>This is notification from B2B portal,&nbsp;</p><p>we want to inform you that a new Invoice has been completed in B2B. Please check your Invoice index for more information.</p><p>If you have any problem in this process, please feel free for contact your system administrator.</p><p>&nbsp;</p><p>Thank you,</p>',
      subject: "Notification Invoice Completed", email_type: 1, type_po: "Invoice"
  else
    puts "do nothing"
  end
end