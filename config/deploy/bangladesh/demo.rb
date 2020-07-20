server "ec2-13-233-166-168.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron seed_data]
server "ec2-3-6-91-15.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
