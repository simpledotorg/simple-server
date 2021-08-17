server "ec2-13-232-113-147.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron]
server "ec2-13-233-251-139.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db]
server "ec2-3-7-252-193.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
