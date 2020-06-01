server "ec2-13-235-33-14.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron whitelist_phone_numbers seed_data]
server "ec2-3-7-70-9.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
