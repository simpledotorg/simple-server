module Mergeable
  extend ActiveSupport::Concern

  included do
    attr_accessor :merge_status
  end

  class_methods do
    def merge(attributes)
      new_record = new(attributes)
      existing_record = find_by(id: attributes['id'])

      if new_record.invalid?
        invalid_record(new_record)
      elsif existing_record.nil?
        create_new_record(attributes)
      elsif new_record.device_updated_at > existing_record.device_updated_at
        update_existing_record(existing_record, attributes)
      else
        return_old_record(existing_record)
      end
    end

    private

    def existing_record(attributes)
      find(attributes['id'])
    end

    def invalid_record(new_record)
      logger.debug "#{self} with id #{new_record.id} is invalid"
      new_record.merge_status = :invalid
      new_record
    end

    def create_new_record(attributes)
      logger.debug "#{self} with id #{attributes['id']} is new, creating."
      record = create(attributes)
      record.merge_status = :new
      record
    end

    def update_existing_record(existing_record, attributes)
      logger.debug "#{self} with id #{existing_record.id} is existing, updating."
      existing_record.update(attributes)
      existing_record.merge_status = :updated
      existing_record
    end

    def return_old_record(existing_record)
      logger.debug "#{self} with id #{existing_record.id} is old, keeping existing."
      existing_record.touch
      existing_record.merge_status = :old
      existing_record
    end
  end

  def merged?
    %i[new updated].include? merge_status
  end
end
