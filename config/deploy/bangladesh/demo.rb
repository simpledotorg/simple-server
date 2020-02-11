server "ec2-13-233-161-111.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db sidekiq cron)
server "ec2-13-126-143-36.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(sidekiq)
