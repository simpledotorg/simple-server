module Mergeable
  extend ActiveSupport::Concern

  included do
    attr_accessor :merge_status
    has_many :audit_logs, as: :auditable
  end

  class_methods do
    def compute_merge_status(attributes)
      new_record = new(attributes)
      existing_record = with_discarded.find_by(id: attributes['id'])

      case
      when new_record.invalid?
        :invalid
      when existing_record.nil?
        :new
      when existing_record.discarded?
        :discarded
      when new_record.device_updated_at > existing_record.device_updated_at
        :updated
      else
        :old
      end
    end

    def merge(attributes)
      new_record = new(attributes)
      existing_record = with_discarded.find_by(id: attributes['id'])

      case compute_merge_status(attributes)
      when :discarded
        discarded_record(new_record)
      when :invalid
        invalid_record(new_record)
      when :new
        create_new_record(attributes)
      when :updated
        update_existing_record(existing_record, attributes)
      when :old
        return_old_record(existing_record)
      end
    end

    private

    def existing_record(attributes)
      find(attributes['id'])
    end

    def discarded_record(record)
      logger.debug "#{self} with id #{record.id} is already discarded"
      NewRelic::Agent.increment_metric("Merge/#{self}/discarded")
      record.merge_status = :discarded
      record
    end

    def invalid_record(new_record)
      logger.debug "#{self} with id #{new_record.id} is invalid"
      NewRelic::Agent.increment_metric("Merge/#{self}/invalid")
      new_record.merge_status = :invalid
      new_record
    end

    def create_new_record(attributes)
      logger.debug "#{self} with id #{attributes['id']} is new, creating."
      NewRelic::Agent.increment_metric("Merge/#{self}/new")
      record = create(attributes)
      record.merge_status = :new
      record
    end

    def update_existing_record(existing_record, attributes)
      logger.debug "#{self} with id #{existing_record.id} is existing, updating."
      NewRelic::Agent.increment_metric("Merge/#{self}/updated")
      existing_record.update(attributes)
      existing_record.merge_status = :updated
      existing_record
    end

    def return_old_record(existing_record)
      logger.debug "#{self} with id #{existing_record.id} is old, keeping existing."
      NewRelic::Agent.increment_metric("Merge/#{self}/old")
      existing_record.touch
      existing_record.merge_status = :old
      existing_record
    end
  end

  def merged?
    %i[new updated].include? merge_status
  end
end
