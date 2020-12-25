class BlockLevelSync
  class << self
    def disable(user_ids)
      new.toggle_state(user_ids, false)
    end

    def enable(user_ids)
      new.toggle_state(user_ids, true)
    end

    def bump(percentage)
      new.bump(percentage)
    end
  end

  def toggle_state(user_ids, enable)
    user_ids.each do |user_id|
      user = User.find_by(id: user_id)

      unless user
        return Rails.logger.info "User #{user_id} not found"
      end

      ActiveRecord::Base.transaction do
        unless user.phone_number_authentication
          return Rails.logger.info "User #{user.id} does not have a phone number authentication"
        end

        user.facility_group.facilities.update_all(updated_at: Time.current)

        if enable
          Flipper.enable(:block_level_sync, user)
        else
          Flipper.disable(:block_level_sync, user)
        end

        Rails.logger.info "Block level sync #{enable ? "enabled" : "disabled"} for #{user.id}"
      end
    end
  end

  def bump(percentage)
    existing_percentage = Flipper[:block_level_sync].percentage_of_actors_value
    existing_enabled_user_ids = enabled_user_ids.to_set

    ActiveRecord::Base.transaction do
      Flipper.enable_percentage_of_actors(:block_level_sync, existing_percentage + percentage)

      newly_enabled_user_ids = enabled_user_ids.to_set - existing_enabled_user_ids.to_set
      newly_enabled_user_ids.each { |user_id| touch_facilities(User.find(user_id)) }

      newly_enabled_user_ids.each do |user_id|
        Rails.logger.info msg: "Block level sync enabled for #{user_id}",
                          block_level_sync_enabled_user_id: user_id
      end
    end

    Rails.logger.info msg: "Triggering the cache warmer to ensure that facilities have the latest cache..."
    Reports::RegionCacheWarmer.call
  end

  private

  def touch_facilities(user)
    user
      .facility_group
      .facilities
      .update_all(updated_at: Time.current)
  end

  def enabled_user_ids
    User.all.select { |u| u.feature_enabled?(:block_level_sync) }.pluck(:id)
  end
end
