Rails.application.configure do
  config.application_brand_name = ENV.fetch('APPLICATION_BRAND_NAME', 'Simple')
  config.team_email_id = ENV.fetch('TEAM_EMAIL_ID', 'team@simple.org')
  config.help_email_id = ENV.fetch('HELP_EMAIL_ID', 'help@simple.org')
  config.cvho_email_id = ENV.fetch('CVHO_EMAIL_ID', 'cvho@simple.org')
end
