server "ec2-13-235-33-14.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db cron whitelist_phone_numbers seed)
server "ec2-15-206-123-187.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web sidekiq)
