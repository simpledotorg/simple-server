class Hash
  def with_int_timestamps
    ts_keys = %w[recorded_at created_at updated_at device_created_at device_updated_at age_updated_at otp_expires_at deleted_at requested_at]
    each_pair do |key, value|
      if ts_keys.include?(key) && value.present?
        self[key] = value.to_time.to_i
      elsif value.is_a? Hash
        self[key] = value.with_int_timestamps
      elsif ts_keys.include?(key) && value.is_a?(Array)
        self[key] = value.map(&:with_int_timestamps)
      end
      self
    end
    self
  end

  def to_json_and_back
    JSON(to_json)
  end

  def with_payload_keys
    Api::V3::Transformer.rename_attributes(
      self, Api::V3::Transformer.to_response_key_mapping
    )
  end
end

def reset_controller
  controller.instance_variable_set(:@current_facility_records, nil)
  controller.instance_variable_set(:@other_facility_records, nil)
  controller.instance_variable_set(:@current_facility, nil)
end

# This utility method injects helper methods defined in a controller into a view spec context.
# Purpose:
# In Rails, helper methods defined in controllers are not automatically included in view specs.
# This method allows for the injection of these helper methods into the context of a view spec, 
# enabling their use in tests.
# Parameters:
# - controller_class: The controller class from which to extract the helper methods.
# - context: The context (typically `self`) where the helper methods will be injected, 
#   allowing the view spec to access and use them.
# Usage:
# Call this method within a view spec setup to ensure that controller helper methods 
# are available during the test:
# inject_controller_helper_methods(MyController, self)
# This method dynamically defines the helper methods on the context provided, 
# making them accessible within the view spec.
def inject_controller_helper_methods(controller_class, context)
  helper_module = (controller = controller_class.new)._helpers
  helper_methods = helper_module.instance_methods(false).sort
  helper_method = ->(method) { helper_module.instance_method(method) }

  helper_methods.each do |method|
    context.class.define_method(method, helper_method[method])
  end
end
