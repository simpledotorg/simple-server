# Use https://github.com/charkost/prosopite to log N+1 queries
Prosopite.rails_logger = true unless Rails.env.production?
