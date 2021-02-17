module FetchMultiFix
  def fetch_multi(*names)
    options = names.extract_options!
    if options[:force]
      hash = names.each_with_object({}) { |name, hsh|
        hsh[name] = yield(name)
      }
      write_multi(hash)
      hash
    else
      super
    end
  end
end

ActiveSupport::Cache::Store.prepend(FetchMultiFix)
