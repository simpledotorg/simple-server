class ApiVersionGenerator < Rails::Generators::Base
  source_root(Rails.root)
  class_option :current_version, type: :string
  class_option :new_version, type: :string

  attr_reader :current_version, :new_version

  def set_versions
    @current_version = options['current_version']
    @new_version = options['new_version']
  end

  def create_specs_for_version
    create_copy_of_spec_directory('spec/api')
    create_copy_of_spec_directory('spec/controllers/api')
    create_copy_of_spec_directory('spec/payloads/api')
    create_copy_of_spec_directory('spec/requests/api')
  end

  def create_controllers_for_version
    create_template_for_directory(
      'app/controllers',
      'lib/generators/api_version/templates/empty_inheriting_class.rb.tt'
    )
  end

  def create_transformers_for_version
    create_template_for_directory(
      'app/transformers',
      'lib/generators/api_version/templates/empty_inheriting_class.rb.tt'
    )
  end

  def create_schema_for_version
    directory('app/schema/api/current', "app/schema/api/#{current_version}")
  end

  private

  def create_copy_of_spec_directory(directory_path)
    current_version_path = "#{directory_path}/#{current_version}"
    directory("#{directory_path}/current", current_version_path)
    Dir["#{destination_root}/#{current_version_path}/**/*.rb"].each do |path|
      gsub_file(path, 'current', current_version)
      gsub_file(path, 'Current', current_version.capitalize)
    end
  end

  def create_template_for_directory(base_path, template_file)
    destination_dir = "#{base_path}/api/#{current_version}"
    empty_directory(destination_dir)
    existing_files = Dir[Rails.root.join(base_path, 'api', 'current/**/*.rb')]

    existing_files.each do |path|
      relative_path = path.remove(Rails.root.join(base_path).to_s)
      create_template_for_file(relative_path, base_path, template_file)
    end
  end

  def create_template_for_file(relative_path, base_path, template_file)
    new_relative_path = relative_path.sub('current', current_version)

    @inheriting_class_name = class_name_for_path(relative_path)
    @new_class_name = class_name_for_path(new_relative_path)

    template(template_file, base_path + new_relative_path)
  end

  def class_name_for_path(path)
    path.remove('.rb')
      .split('/')
      .reject(&:empty?)
      .map(&:camelcase)
      .join('::')
  end
end
