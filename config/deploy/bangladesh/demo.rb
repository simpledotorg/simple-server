server "ec2-13-232-175-77.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron seed_data]
server "ec2-15-206-203-213.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
