server "ec2-3-6-38-148.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db cron whitelist_phone_numbers)
server "ec2-13-235-13-52.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db)
server "ec2-13-232-141-5.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(sidekiq)
