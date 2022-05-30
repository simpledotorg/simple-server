server "ec2-3-108-55-106.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron seed_data]
server "ec2-13-232-2-56.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
