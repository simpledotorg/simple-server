# A user-defined goal, tracked by marking it complete rather than by data
module DrRai
  class CustomIndicator < Indicator
    def datasource(region)
      nil
    end

    def display_name
      "Create my own"
    end

    def target_type_frontend
      "boolean"
    end

    def tooltip
      "To track something not listed, select this option to create your own"
    end

    def unit
      ""
    end

    def action_passive
      ""
    end

    def action_active
      ""
    end

    def is_supported?(region)
      true
    end

    def has_action_plans?(region, period)
      false
    end
  end
end
