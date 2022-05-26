server "ec2-3-109-144-155.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron whitelist_phone_numbers seed_data]
server "ec2-3-108-193-51.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
