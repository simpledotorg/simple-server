server "ec2-13-127-62-208.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db cron)
server "ec2-3-6-91-15.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web sidekiq)
