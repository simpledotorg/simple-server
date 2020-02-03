server "ec2-13-232-111-97.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db cron whitelist_phone_numbers)
server "ec2-13-233-223-150.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db)
server "ec2-52-66-108-246.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(sidekiq)
