desc "Enable block level sync for users"
task enable_block_level_sync: :environment do |_t, args|
  # bundle exec enable_block_level_sync[user_id_1,user_id_2,...]

  user_ids = args.extras
  puts user_ids.map { |user_id|
    user = User.find_by(id: user_id)
    next "User with id #{user_id} not found" unless user

    Flipper.enable(:region_level_sync, user)
    user.facility_group.facilities.update_all(updated_at: Time.current)
    "Block level sync enabled for #{user_id}"
  }
end
