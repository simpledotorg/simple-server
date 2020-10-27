ActiveSupport::Notifications.subscribe(/cache_.*\.active_support/) do |name, start, finish, arg1, arg2|
  Rails.logger.debug name: name, start: start, finish: finish, arg1: arg1, arg2: arg2
end

ActiveSupport::Notifications.subscribe(/cache_read\.active_support/) do |name, start, finish, _id, payload|
  RequestStore[:cache_stats] ||= {reads: 0, hits: 0, misses: 0}
  RequestStore[:cache_stats][:reads] += 1
  if payload[:hit]
    RequestStore[:cache_stats][:hits] += 1
  else
    RequestStore[:cache_stats][:misses] += 1
  end
end

ActiveSupport::Notifications.subscribe(/cache_read_multi\.active_support/) do |name, start, finish, _id, payload|
  RequestStore[:cache_stats] ||= {reads: 0, hits: 0, misses: 0}
  RequestStore[:cache_stats][:reads] += 1
  hits = if payload[:hits]
    payload[:hits].size
  else
    0
  end
  RequestStore[:cache_stats][:hits] += hits
  RequestStore[:cache_stats][:misses] += payload[:key].size - hits
end
