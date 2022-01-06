# frozen_string_literal: true

module Mergeable
  extend ActiveSupport::Concern

  included do
    attr_accessor :merge_status
  end

  class_methods do
    def compute_merge_status(attributes)
      new_record = new(attributes)
      existing_record = with_discarded.find_by(id: attributes["id"])

      if new_record.invalid?
        :invalid
      elsif existing_record.nil?
        :new
      elsif existing_record.discarded?
        :discarded
      elsif new_record.device_updated_at > existing_record.device_updated_at
        :updated
      elsif new_record.device_updated_at == existing_record.device_updated_at
        :identical
      else
        :old
      end
    end

    def merge(attributes)
      new_record = new(attributes)
      existing_record = with_discarded.find_by(id: attributes["id"])

      case compute_merge_status(attributes)
      when :discarded
        discarded_record(existing_record)
      when :invalid
        invalid_record(new_record)
      when :new
        create_new_record(attributes)
      when :updated
        update_existing_record(existing_record, attributes)
      when :identical
        return_identical_record(existing_record)
      when :old
        return_old_record(existing_record)
      end
    end

    private

    def existing_record(attributes)
      find(attributes["id"])
    end

    def increment_metric(event)
      Statsd.instance.increment("merge.#{self}.#{event}")
    end

    def discarded_record(record)
      logger.debug "#{self} with id #{record.id} is already discarded"
      increment_metric(:discarded)
      record.merge_status = :discarded
      record
    end

    def invalid_record(new_record)
      logger.debug "#{self} with id #{new_record.id} is invalid"
      increment_metric(:invalid)
      new_record.merge_status = :invalid
      new_record
    end

    def create_new_record(attributes)
      logger.debug "#{self} with id #{attributes["id"]} is new, creating."
      increment_metric(:new)

      record = create(attributes)
      record.merge_status = :new
      record
    end

    def update_existing_record(existing_record, attributes)
      logger.debug "#{self} with id #{existing_record.id} is existing, updating."
      increment_metric(:updated)
      existing_record.update(attributes)
      existing_record.merge_status = :updated
      existing_record
    end

    def return_identical_record(existing_record)
      logger.debug "#{self} with id #{existing_record.id} is identical, doing nothing."
      increment_metric(:identical)
      existing_record.merge_status = :identical
      existing_record
    end

    def return_old_record(existing_record)
      logger.debug "#{self} with id #{existing_record.id} is old, keeping existing."
      increment_metric(:old)
      existing_record.touch
      existing_record.merge_status = :old
      existing_record
    end
  end

  def merged?
    %i[new updated].include? merge_status
  end
end
