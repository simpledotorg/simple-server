class ApplicationComponent < ViewComponent::Base
  use_who_standard = Flipper.enabled?(:diabetes_who_standard_indicator)
end
