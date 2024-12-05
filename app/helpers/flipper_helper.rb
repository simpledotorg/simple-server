module FlipperHelper
  def resolve_use_who_standard(use_who_standard)
    use_who_standard.nil? ? Flipper.enabled?(:diabetes_who_standard_indicator) : use_who_standard
  end
end
