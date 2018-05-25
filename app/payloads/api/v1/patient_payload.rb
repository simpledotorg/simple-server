class Api::V1::PatientPayload
  include ActiveModel::Model

  # - swagger validation
  # - build errors
  # - custom validation
  # - build errors
  # - coerce params to ruby/rails data types
  # - build errors
  # - rename keys
  # - structure payload object?

  ResponseValidator.new.validate!(metadata, response)
end