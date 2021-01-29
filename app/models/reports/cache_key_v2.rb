module Reports
  module CacheKeyV2
    def cache_key_v2
      [model_name.cache_key, id, slug].join("/")
    end
  end
end