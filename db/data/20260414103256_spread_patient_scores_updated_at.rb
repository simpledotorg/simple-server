# frozen_string_literal: true

class SpreadPatientScoresUpdatedAt < ActiveRecord::Migration[6.1]
  def up
    # Find the clustered timestamp that's causing sync pagination issues
    # This happens when bulk inserts share the same updated_at
    clustered_timestamps = PatientScore.group(:updated_at)
      .having("count(*) > 1000")
      .count
      .keys

    return if clustered_timestamps.empty?

    clustered_timestamps.each do |clustered_timestamp|
      Rails.logger.info "Spreading updated_at for PatientScores with timestamp: #{clustered_timestamp}"

      # First, check if device_updated_at is well-distributed
      device_updated_distribution = PatientScore
        .where(updated_at: clustered_timestamp)
        .group(:device_updated_at)
        .count
        .sort_by { |_, n| -n }
        .first(5)

      max_device_cluster = device_updated_distribution.first&.last || 0

      if max_device_cluster < 1000
        # device_updated_at is well-distributed, use it
        Rails.logger.info "Using device_updated_at (max cluster: #{max_device_cluster})"
        PatientScore
          .where(updated_at: clustered_timestamp)
          .update_all("updated_at = device_updated_at")
      else
        # device_updated_at is also clustered, spread by id with millisecond offsets
        Rails.logger.info "Spreading by id with millisecond offsets (device_updated_at max cluster: #{max_device_cluster})"
        ActiveRecord::Base.connection.execute(<<-SQL.squish)
          UPDATE patient_scores ps
          SET updated_at = '#{clustered_timestamp}'::timestamp
                         + (sub.row_num * interval '1 millisecond')
          FROM (
            SELECT id, row_number() OVER (ORDER BY id) AS row_num
            FROM patient_scores
            WHERE updated_at = '#{clustered_timestamp}'
          ) sub
          WHERE ps.id = sub.id
        SQL
      end
    end
  end

  def down
    # This migration cannot be reversed as we don't track original values
    raise ActiveRecord::IrreversibleMigration
  end
end
