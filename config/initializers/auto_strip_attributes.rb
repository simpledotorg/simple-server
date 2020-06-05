AutoStripAttributes::Config.setup do
  set_filter(titleize: false) do |value|
    !value.blank? && value.respond_to?(:titleize) ? value.titleize : value
  end

  set_filter(upcase_first: false) do |value|
    !value.blank? && value.respond_to?(:upcase_first) ? value.upcase_first : value
  end
end
