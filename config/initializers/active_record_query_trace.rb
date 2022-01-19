# This is pretty expensive and adds a _lot_ of noise to the logs, so mostly recommended
# for local dev
if ENV["QUERY_TRACE"]
  # See https://github.com/brunofacca/active-record-query-trace for docs
  require "active_record_query_trace"
  ActiveRecordQueryTrace.enabled = true
  ActiveRecordQueryTrace.level = :app
  ActiveRecordQueryTrace.lines = 15
end
