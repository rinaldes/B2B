class UserMailer < ActionMailer::Base
#  default from: "b2b_system"
  helper ApplicationHelper

  def mailer_grn(user, grn, email)
  	@user = user
  	@grn = grn
    if email.try(:subject).blank?
      mail(to: user, subject: '[B2B system] Good Receive Notifications')
    else
      mail(to: user, subject: email.try(:subject))
    end
  end

  def mailer_grpc(user, grpc, email)
  	@user = user
  	@grpc = grpc
    @email = email
    if email.try(:subject).blank?
      mail(to: @user, subject: '[B2B system] Good Receive Price Confirmation')
    else
     mail(to: @user, subject: email.try(:subject))
    end
  end

  def mailer_grtn(user, grtn, email)
    @user = user
    @grtn = grtn
    @email = email
    if email.try(:subject).blank?
      mail(to: @user, subject: 'Subject: [B2B system] Good Return Notification')
    else
      mail(to: @user, subject: email.try(:subject))
    end
  end

  def mailer_notification(po_number, state, users, email, class_name, url)
    @po_number = po_number
    @mail = email
    @users = users.flatten
    @class_name = class_name
    @i = 1
    @url = url
    mail(to: @users.collect(&:email), subject: "#{@mail.try(:subject)} Transaction No: #{po_number}", from: 'b2b_system@pratesis.com')
  end

  def mailer_notificationrp(rp_number, state, users, email)
    @rp_number = rp_number
    @mail = email
    @users = users.flatten
    @i = 1
    mail(to: @users.collect(&:email), subject: "#{@mail.try(:subject)} Transaction No : #{rp_number}")
  end

  def mailer_notification_api_is_not_response(message,arr_user)
    @message = message
    @user = arr_user
    mail(to: @user, subject: "#{@message}")
  end

  def mailer_notification_synchronize(number, users, state, type, url)
    @users = users.flatten
    @number = number
    @state = state
    @url = url
    @type = type
    mail(to: @users.collect(&:email), subject: "#{type} - Transaction No : #{number}", from: 'b2b_system@pratesis.com')
  end

  def mailer_dispute(po_number, users, type)
    @content = DisputeSetting.where(:transaction_type => type).first.email_content rescue nil
    unless @content.nil?
      mail(to: users.join(", "), subject: "#{type} - Transaction No : #{po_number} Dispute Escalated")
    end
  end

end
