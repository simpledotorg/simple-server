server "ec2-52-66-250-216.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db cron)
server "ec2-13-126-205-193.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db)
server "ec2-13-233-151-58.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(sidekiq)
