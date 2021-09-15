class DataScriptGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def create_data_script
    generate(:migration, file_name)
    copy_file "data_script.rb", "lib/data_scripts/#{file_name}.rb"
    copy_file "data_script_spec.rb", "spec/lib/data_scripts/#{file_name}_spec.rb"
  end
end
