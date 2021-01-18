class BlockLevelSync
  class << self
    def disable(user_ids)
      new.toggle_state(user_ids, false)
    end

    def enable(user_ids)
      new.toggle_state(user_ids, true)
    end

    def set_percentage(percentage)
      new.set_percentage(percentage)
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

        touch_facilities(user)

        if enable
          Flipper.enable(:block_level_sync, user)
        else
          Flipper.disable(:block_level_sync, user)
        end

        Rails.logger.info "Block level sync #{enable ? "enabled" : "disabled"} for #{user.id}"
      end
    end
  end

  def set_percentage(percentage)
    existing_enabled_user_ids = enabled_user_ids.to_set

    ActiveRecord::Base.transaction do
      Flipper.enable_percentage_of_actors(:block_level_sync, percentage)

      newly_enabled_user_ids = enabled_user_ids.to_set - existing_enabled_user_ids.to_set
      newly_enabled_user_ids.each do |user_id|
        user = User.find(user_id)
        touch_facilities(user)
      end

      newly_enabled_user_ids.each do |user_id|
        Rails.logger.info({
          msg: "Block level sync enabled for #{user_id}",
          block_level_sync_enabled_user_id: user_id,
          block_level_sync_percentage_enabled: percentage.to_s
        })
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
  rescue Module::DelegationError # skip for users who don't have an associated FG
    nil
  end

  # this filters out admin users since there's no easy way to filter them out during percentage ramp-up
  def enabled_user_ids
    User
      .non_admins
      .find_each(batch_size: 100).each_with_object([]) do |user, ids|
      ids.push(user.id) if user.feature_enabled?(:block_level_sync)
    end
  end
end
