server "ec2-13-232-246-106.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron whitelist_phone_numbers]
server "ec2-13-235-87-60.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db]
server "ec2-15-207-249-249.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
