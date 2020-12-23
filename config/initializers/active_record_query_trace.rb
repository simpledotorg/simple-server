if Rails.env.development?
  # See https://github.com/brunofacca/active-record-query-trace for docs
  ActiveRecordQueryTrace.enabled = true
end