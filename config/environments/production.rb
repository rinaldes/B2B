B2bSystem::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = false

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
  config.action_mailer.delivery_method = :smtp

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

  config.action_mailer.default_url_options = { :host => 'http://10.10.11.4/' }
  config.action_mailer.smtp_settings = {
    :address              => 'mail.pratesis.com',
    :port                 => 465,
    :domain               => 'pratesis.com',
    :user_name            => 'b2b_system',
    :password             => '123pratesis',
    :authentication       => 'login',
    :ssl                  => true,
    :openssl_verify_mode  => 'none'
  }

  # Exception Notifier
  config.middleware.use ExceptionNotification::Rack,
    email: {
      email_prefix:         "[pratesis - B2B System] @ #{Rails.env.to_s} ",
      sender_address:       %{"pratesis B2B System!" <notifier>},
      exception_recipients: %w{winarti51816@gmail.com}
    }

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true


end

PER_PAGE = 10

PO = "Purchase Order"
ASN = "Advance Shipment Notifications"
GRN = "Goods Receive Notes"
GRPC = "Goods Receive Price Confirmations"
INV = "Invoice"
IRR = "Invoice Receipt and Response"
DN = "Debit Notes"
RP = "Returned Process"
GRTN = "Goods Return Note"
PV = "Payment Voucher"
EPR = "Early Payment Request"

BASE_URI = "http://10.10.11.4/"
#API_URI = "http://10.10.11.2:8080/b2b/api/"
#API_KEY = "12345678"
USE_SSL = false
RECEIVE_EMAIL_API_IS_NOT_CONNECTED = ["winarti51816@gmail.com"]