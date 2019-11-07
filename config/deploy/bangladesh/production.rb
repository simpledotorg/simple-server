server "ec2-13-235-245-61.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db cron whitelist_phone_numbers)
server "ec2-15-206-69-33.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db)
server "ec2-13-126-253-41.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(sidekiq)