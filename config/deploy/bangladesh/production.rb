server "ec2-13-232-216-97.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron]
server "ec2-13-234-48-121.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db]
server "ec2-13-232-171-227.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
