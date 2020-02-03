server "ec2-13-127-221-249.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db sidekiq cron whitelist_phone_numbers seed)
