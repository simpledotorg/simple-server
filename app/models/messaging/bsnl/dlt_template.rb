class Messaging::Bsnl::DltTemplate
  MAX_VARIABLE_LENGTH = 30
  DEFAULT_VERSION_NUMBER = 1
  TRIMMABLE_VARIABLES = %i[facility_name patient_name].freeze
  BSNL_TEMPLATES = YAML.load_file("config/data/bsnl_templates.yml")
  STATUSES = {
    "0" => :pending_naming,
    "1" => :approved
  }

  attr_reader :name
  attr_reader :id
  attr_reader :keys
  attr_reader :is_unicode
  attr_reader :max_length_permitted
  attr_reader :non_variable_text_length
  attr_reader :variable_length_permitted
  attr_reader :status
  attr_reader :version
  attr_reader :is_latest_version

  def initialize(dlt_template_name)
    @name = dlt_template_name
    details = template_details(dlt_template_name)
    @id = details["Template_Id"]
    @status = STATUSES[details["Template_Status"]]
    @is_unicode = details["Is_Unicode"]
    @keys = details["Template_Keys"]
    @version = details["Version"]
    @is_latest_version = details["Is_Latest_Version"]
    @max_length_permitted = details["Max_Length_Permitted"].to_i
    @non_variable_text_length = details["Non_Variable_Text_Length"].to_i
    @variable_length_permitted = max_length_permitted - non_variable_text_length
  end

  def self.latest_name_of(dlt_template_name)
    BSNL_TEMPLATES
      .transform_keys { |template_name| drop_version_number(template_name) }
      .dig(drop_version_number(dlt_template_name), "Latest_Template_Version")
  end

  def self.drop_version_number(dlt_template_name)
    dlt_template_name.chomp(".#{version_number(dlt_template_name)}")
  end

  def self.version_number(dlt_template_name)
    version = dlt_template_name.split(".").last

    if numeric?(version)
      version.to_i
    else
      DEFAULT_VERSION_NUMBER
    end
  end

  def sanitised_variable_content(content)
    content.compact
      .then { |c| check_variables_presence(c) }
      .then { |c| trim_variables(c) }
      .then { |c| limit_total_variable_length(c) }
      .then { |c| check_total_variable_length(c) }
      .map { |k, v| {"Key" => k.to_s, "Value" => v} }
  end

  def check_variables_presence(content)
    missing_keys = find_missing_keys(content)
    return content unless missing_keys.present?

    raise Messaging::Bsnl::MissingVariablesError.new(
      "Variables #{missing_keys.to_sentence} not provided to #{name}"
    )
  end

  def check_approved
    raise Messaging::Bsnl::TemplateError.new("Template #{name} is pending naming") unless approved?
  end

  def approved?
    status == :approved
  end

  def trim_variables(content)
    content.transform_values { |value| value[0, MAX_VARIABLE_LENGTH] }
  end

  def limit_total_variable_length(content)
    trimmable_content = content.slice(*TRIMMABLE_VARIABLES)
    non_trimmable_content = content.except(*TRIMMABLE_VARIABLES)
    non_trimmable_content_length = non_trimmable_content.values.map(&:size).sum
    permitted_length = variable_length_permitted - non_trimmable_content_length

    resize_variables_equally(permitted_length, trimmable_content).merge(non_trimmable_content)
  end

  def check_total_variable_length(content)
    variable_length = content.values.map(&:size).sum
    return content unless variable_length > variable_length_permitted

    raise Messaging::Bsnl::VariablesLengthError.new(
      "Variables #{content.values} exceeded #{name}'s variable limit"
    )
  end

  private

  def template_details(dlt_template_name)
    details = BSNL_TEMPLATES.dig(dlt_template_name)
    raise Messaging::Bsnl::TemplateError.new("Template #{dlt_template_name} not found") unless details

    details
  end

  def find_missing_keys(content)
    keys - content.keys.map(&:to_s)
  end

  def resize_variables_equally(permitted_length, content)
    return content if content.values.map(&:size).sum <= permitted_length

    lengths = Hash.new(0)
    variable_names = content.keys
    cycled_over_variables = variable_names.cycle

    until permitted_length <= 0
      var = cycled_over_variables.next
      if lengths[var] < content[var].size
        permitted_length -= 1
        lengths[var] += 1
      end
    end

    content.to_h do |k, v|
      [k, v[0, lengths[k]]]
    end
  end

  class << self
    def numeric?(string)
      !Float(string).nil?
    rescue
      false
    end
  end
end
