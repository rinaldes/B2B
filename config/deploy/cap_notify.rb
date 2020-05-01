require "action_mailer"

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port                 => 587,
  :domain               => '@gmail.com',
  :user_name            => 'noreply.b2bsystem',
  :password             => 'Db3/o[uwTBpTK3X',
  :authentication       => 'plain',
  :enable_starttls_auto => true
}

class Notifier < ActionMailer::Base
  default :from => "Deploy Notification"

  def deploy_notification(cap_vars)
    now = Time.now
    msg = "Performed a deploy operation on #{now.strftime("%m/%d/%Y")} at #{now.strftime("%I:%M %p")} to #{cap_vars.stage}"

    mail(:to => cap_vars.notify_emails,
         :subject => "[Pratesis - B2B System] #{cap_vars.stage} has been deployed!") do |format|
      format.text { render :text => msg}
      format.html { render :text => "<p>" + msg + "<\p>"}
    end
  end
end