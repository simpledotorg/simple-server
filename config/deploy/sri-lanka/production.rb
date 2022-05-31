server "ec2-13-233-81-169.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron]
server "ec2-3-109-55-210.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db]
server "ec2-65-1-248-216.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
