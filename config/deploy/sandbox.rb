server "ec2-3-110-215-50.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron whitelist_phone_numbers seed_data]
server "ec2-13-127-222-227.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
