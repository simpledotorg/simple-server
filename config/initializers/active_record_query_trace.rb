enable_query_trace = ENV["QUERY_TRACE"]
if (Rails.env.development? || Rails.env.test?) && enable_query_trace
  # See https://github.com/brunofacca/active-record-query-trace for docs
  require "active_record_query_trace"
  ActiveRecordQueryTrace.enabled = true
  ActiveRecordQueryTrace.level = :app
  ActiveRecordQueryTrace.lines = 15
end
