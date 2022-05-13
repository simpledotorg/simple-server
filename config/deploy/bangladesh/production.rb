server "ec2-13-235-84-237.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron]
server "ec2-3-110-236-106.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db]
server "ec2-65-0-66-193.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
