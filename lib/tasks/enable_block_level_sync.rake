desc "Enable block level sync for users"
task enable_block_level_sync: :environment do |_t, args|
  # bundle exec enable_block_level_sync[user_id_1,user_id_2,...]
  user_ids = args.extras

  user_ids.each do |user_id|
    user = User.find_by(id: user_id)
    if user
      enable_block_level_sync(user)
    else
      Rails.logger.info "User #{user_id} not found" unless user
    end
  end
end

def enable_block_level_sync(user)
  ActiveRecord::Base.transaction do
    if user.phone_number_authentication
      user.facility_group.facilities.update_all(updated_at: Time.current)
      Flipper.enable(:region_level_sync, user)

      Rails.logger.info "Block level sync enabled for #{user.id}"
    else
      Rails.logger.info "User #{user.id} does not have a phone number authentication"
    end
  end
end
