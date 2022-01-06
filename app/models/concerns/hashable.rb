# frozen_string_literal: true

module Hashable
  module_function

  def hash_uuid(original_uuid)
    return nil if original_uuid.blank?

    UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, {uuid: original_uuid}.to_s).to_s
  end
end
