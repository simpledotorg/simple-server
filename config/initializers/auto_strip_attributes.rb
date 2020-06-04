AutoStripAttributes::Config.setup do
  set_filter(titleize: false) do |value|
    !value.blank? && value.respond_to?(:titleize) ? value.titleize : value
  end
end
