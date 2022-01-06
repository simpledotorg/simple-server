# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include Discard::Model

  self.discard_column = :deleted_at
  self.abstract_class = true

  default_scope { kept }

  def self.updated_on_server_since(timestamp, number_of_records = nil)
    where("#{table_name}.updated_at >= ?", timestamp)
      .order(:updated_at)
      .limit(number_of_records)
  end

  def readonly?
    RequestStore[:readonly] || @readonly
  end
end
