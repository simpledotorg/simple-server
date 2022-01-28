server "ec2-3-110-215-50.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron whitelist_phone_numbers seed_data]
server "ec2-52-66-125-161.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
