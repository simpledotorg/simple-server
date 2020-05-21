server "ec2-52-66-250-216.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron whitelist_phone_numbers]
server "ec2-13-126-205-193.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db]

server "ec2-13-232-216-64.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db]
server "ec2-15-206-127-129.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db]

server "ec2-13-126-110-54.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
