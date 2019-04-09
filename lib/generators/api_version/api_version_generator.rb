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
    create_api_specs_for_current_version
    create_controller_specs_for_current_version
  end

  # def create_schema_for_version
  #   directory('app/schema/api/current', "app/schema/api/#{current_version}")
  # end

  private

  def create_api_specs_for_current_version
    current_version_path = "spec/api/#{current_version}"
    directory('spec/api/current', current_version_path)
    Dir["#{destination_root}/#{current_version_path}/**/*_spec.rb"].each do |path|
      gsub_file(path, 'current/swagger.json', "#{current_version}/swagger.json")
      gsub_file(path, 'Current', current_version.capitalize)
    end
  end

  def create_controller_specs_for_current_version
    current_version_path = "spec/controllers/api/#{current_version}"
    directory('spec/controllers/api/current', current_version_path)
    Dir["#{destination_root}/#{current_version_path}/**/*_spec.rb"].each do |path|
      gsub_file(path, 'current', current_version)
      gsub_file(path, 'Current', current_version.capitalize)
    end
  end
end
