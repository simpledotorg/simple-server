# This will print all notification strings in the format the Katalon Recorder needs.
# You can filter the outut or tweak these commands to include only the ones you want to upload.
# Katalon Recorder: https://chrome.google.com/webstore/detail/katalon-recorder-selenium/ljdobmomdgdljniojadhoplhkpialdid
include I18n::Backend::Flatten
languagewise_strings = Dir.glob("config/locales/notifications/*").map do |file_name|
  flatten_translations(nil, YAML.safe_load(File.open(file_name)), nil, false)
end

languagewise_strings.flat_map(&:to_a).to_h.sort_by(&:first).map { |k, v| {"name" => k.to_s, "message" => v} }.to_json
