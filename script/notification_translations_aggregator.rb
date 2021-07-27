# Call from within script directory: bundle exec ruby notification_translations_aggregator.rb

require "yaml"

formatted_messages = {}
date = Time.now.strftime("%Y-%m-%d")
sets = %w[
  set01
  set02
  set03
]
names = %w[
  basic
  gratitude
  free
  alarm
  emotional_relatives
  emotional_guilt
  professional_request
  response
]

def format_message(message)
  i = 0
  message.gsub(/%{[^}]+}/) do
    i += 1
    "{{#{i}}}"
  end
end

Dir["../config/locales/notifications/*.yml"].each do |filename|
  locale = YAML.load_file(filename)
  language = locale.keys.first

  sets.each do |set|
    names.each do |name|
      key = "#{date}.#{set}.#{name}.#{language}"
      message = locale[language]["notifications"][set][name]

      formatted_messages[key] = format_message(message)
    end
  end
end

formatted_messages.sort.each do |key, message|
  puts "#{key} -> #{message}"
end
