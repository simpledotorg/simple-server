server "ec2-65-2-161-138.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron seed_data]
server "ec2-13-233-30-147.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
