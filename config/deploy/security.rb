server "ec2-13-127-26-45.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron whitelist_phone_numbers]
server "ec2-13-234-115-73.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db]
server "ec2-13-234-17-30.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
