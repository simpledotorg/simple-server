server "ec2-15-206-165-200.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron seed_data]
server "ec2-15-206-194-112.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
