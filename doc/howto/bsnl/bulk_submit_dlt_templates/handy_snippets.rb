# Some snippets that'll come handy while uploading/naming templates from a rails console.
# Test them once before running, they might get outdated.
class NotificationStringsForKatalon
  # This will print all notification strings in the format the Katalon Recorder needs.
  # You can filter the output or tweak these commands to include only the ones you want to upload.
  # Katalon Recorder: https://chrome.google.com/webstore/detail/katalon-recorder-selenium/ljdobmomdgdljniojadhoplhkpialdid
  def self.all_strings
    include I18n::Backend::Flatten
    Dir.glob("config/locales/notifications/*").map do |file_name|
      flatten_translations(nil, YAML.safe_load(File.open(file_name)), nil, false)
    end
  end

  def self.for_katalon
    all_strings.flat_map(&:to_a).to_h.sort_by(&:first).
      map do |k, v|
      {
        "name" => k.to_s,
        "message" => v.gsub("%{patient_name}", "{#var#}").gsub("%{facility_name}", "{#var#}").gsub("%{appointment_date}", "{#var#}")
      }
    end
  end

  puts for_katalon
end

class NameUnnamedTemplatesOnBulkSms
  def self.perform
    include I18n::Backend::Flatten

    all_strings = Dir.glob("config/locales/notifications/*").map do |file_name|
      flatten_translations(nil, YAML.safe_load(File.open(file_name)), nil, false)
    end.flat_map(&:to_a).to_h.transform_keys(&:to_s)

    bsnl_templates = YAML.load_file("config/data/bsnl_templates.yml")

    pending = bsnl_templates.select { |_, details| details["Template_Status"] == "0" }.map { |template_name, details| [details["Template_Id"], template_name] }
    pending_ids = pending.to_h.map { |k, v| [v[0..-3], k] }.to_h
    result = all_strings.map { |k, v| [k, v, pending_ids[k]] }.select { |a| a.third.present? }

    list = result.map { |a| [a.third, a.second.gsub("%{", "{#").gsub("}", "#}")] }
    api = Messaging::Bsnl::Api.new

    list.map do |id, string|
      api.name_template_variables(id, string)
    end
  end
end

