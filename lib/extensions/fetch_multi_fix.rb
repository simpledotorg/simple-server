# frozen_string_literal: true

# Created to work around a bug in Rails: https://github.com/rails/rails/issues/41535
# Once the upstream bug is fixed, this workaround can be removed.
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
