class AppUsersToEDN
  class << self
    def write_to_edn(fname, users)
      File.write("/tmp/#{fname}.edn", {users: users}.to_edn)
    end

    def users
      User
        .non_admins
        .joins(:phone_number_authentications)
        .where(sync_approval_status: "allowed")
        .reject { |u| u.registration_facility.blank? }
        .map { |u|
          {
            id: u.id,
            access_token: u.access_token,
            facility_id: u.registration_facility.id,
            sync_region_id: u.registration_facility.region.block_region.id
          }
        }
    end

    def convert
      write_to_edn("sync_to_user.edn", users)
    end

    def convert_for_block_sizes
      small, medium, large = *[1000, 5000, 12_000]
      block_regions = Region.block_regions

      block_dist = block_regions.reduce({small: [], medium: [], large: []}) do |acc, block|
        count = block.syncable_patients.count

        if count <= small
          acc[:small] << block.id
        elsif count <= medium
          acc[:medium] << block.id
        elsif count <= large
          acc[:large] << block.id
        else
          raise RuntimeError, "Block size larger than #{large}, increase the preset of 'large'."
        end

        acc
      end

      small_blocks = block_dist[:small]
      medium_blocks = block_dist[:medium]
      large_blocks = block_dist[:large]

      total_blocks = (small_blocks + medium_blocks + large_blocks)
      raise RuntimeError, "Blocks split by presets != to total blocks." if (total_blocks.size < block_regions.size)

      user_in_block = -> (u, blocks) { u[:sync_region_id].in?(blocks) }

      small_block_users = users.select { |u| user_in_block.(u, small_blocks) }
      write_to_edn("sync_to_user_sm", small_block_users)
      medium_block_users = users.select { |u| user_in_block.(u, medium_blocks) }
      write_to_edn("sync_to_user_md", medium_block_users)
      large_block_users = users.select { |u| user_in_block.(u, large_blocks) }
      write_to_edn("sync_to_user_lg", large_block_users)
    end
  end
end
