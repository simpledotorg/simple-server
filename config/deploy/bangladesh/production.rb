server "ec2-13-234-38-169.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db cron)
server "ec2-13-127-239-96.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db)
server "ec2-52-66-210-7.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(sidekiq)
