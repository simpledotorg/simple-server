module Mergeable
  extend ActiveSupport::Concern

  included do
    attr_accessor :merge_status
  end

  class_methods do
    def merge(attributes)
      return nil unless attributes.present?

      new_record = new(attributes)
      existing_record = find_by(id: attributes['id'])

      if new_record.invalid?
        invalid_record(new_record)
      elsif existing_record.nil?
        create_new_record(attributes)
      elsif attributes['updated_at'] > existing_record.updated_at
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
      new_record.merge_status = :invalid
      new_record
    end

    def create_new_record(attributes)
      record = create(attributes.merge(updated_on_server_at: Time.now))
      record.merge_status = :new
      record
    end

    def update_existing_record(existing_record, attributes)
      existing_record.update(attributes.merge(updated_on_server_at: Time.now))
      existing_record.merge_status = :updated
      existing_record
    end

    def return_old_record(existing_record)
      existing_record.update_column('updated_on_server_at', Time.now)
      existing_record.merge_status = :old
      existing_record
    end
  end

  def merged?
    %i[new updated].include? merge_status
  end
end
