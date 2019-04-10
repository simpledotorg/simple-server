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
    api_root = 'app/controllers/api'
    destination_dir = "#{destination_root}/#{api_root}/#{current_version}"

    empty_directory(destination_dir)

    existing_controller_files = Dir["#{Rails.root.to_s}/#{api_root}/current/**/*.rb"]

    existing_controller_files.each do |path|
      @controller_file_name = path.split('/').last
      @controller_class_name = @controller_file_name.split('.').first.camelcase

      template('lib/generators/api_version/templates/controller.rb.erb',
               "#{destination_dir}/#{@controller_file_name}")
    end
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
end
