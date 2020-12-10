namespace :block_level_sync do
  desc "Enable block level sync for users"
  task enable: :environment do |_t, args|
    # bundle exec block_level_sync:enable[user_id_1,user_id_2,...]
    user_ids = args.extras

    user_ids.each do |user_id|
      user = User.find_by(id: user_id)
      if user
        set_block_level_sync(user, true)
      else
        Rails.logger.info "User #{user_id} not found"
      end
    end
  end

  desc "Disable block level sync for users"
  task disable: :environment do |_t, args|
    # bundle exec block_level_sync:disable[user_id_1,user_id_2,...]
    user_ids = args.extras

    user_ids.each do |user_id|
      user = User.find_by(id: user_id)
      if user
        set_block_level_sync(user, false)
      else
        Rails.logger.info "User #{user_id} not found"
      end
    end
  end
end

def set_block_level_sync(user, enable)
  ActiveRecord::Base.transaction do
    if user.phone_number_authentication
      user.facility_group.facilities.update_all(updated_at: Time.current)
      if enable
        Flipper.enable(:block_level_sync, user)
      else
        Flipper.disable(:block_level_sync, user)
      end
      Rails.logger.info "Block level sync #{ enable ? "enabled" : "disabled"} for #{user.id}"
    else
      Rails.logger.info "User #{user.id} does not have a phone number authentication"
    end
  end
end
