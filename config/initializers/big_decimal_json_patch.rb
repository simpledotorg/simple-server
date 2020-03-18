require 'active_support'
require 'active_support/core_ext/object/json'

class BigDecimal
  def as_json(*)
    to_f
  end
end
