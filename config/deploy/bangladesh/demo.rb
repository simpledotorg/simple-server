server "ec2-13-233-8-130.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron seed_data]
server "ec2-15-207-249-148.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
