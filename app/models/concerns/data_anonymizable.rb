module DataAnonymizable
  extend ActiveSupport::Concern

  UNAVAILABLE = 'Unavailable'

  class_methods do
    def hash_uuid(original_uuid)
      UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, { uuid: original_uuid }.to_s).to_s
    end

    def original_else_blank_value(value)
      if value.blank?
        UNAVAILABLE
      else
        value
      end
    end

    def hashed_else_blank_value(value)
      if value.blank?
        UNAVAILABLE
      else
        hash_uuid(value)
      end
    end
  end
end