server "ec2-65-0-103-246.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron whitelist_phone_numbers seed_data]
server "ec2-13-127-222-227.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
