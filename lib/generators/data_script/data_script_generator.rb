class DataScriptGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def create_data_script
    template "data_script.erb", "lib/data_scripts/#{file_name}_script.rb"
    template "data_script_spec.erb", "spec/lib/data_scripts/#{file_name}_script_spec.rb"
  end
end
