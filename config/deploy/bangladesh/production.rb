server "ec2-3-110-211-60.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron]
server "ec2-3-110-137-28.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db]
server "ec2-13-234-56-146.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
