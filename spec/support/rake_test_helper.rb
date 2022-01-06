# frozen_string_literal: true

module RakeTestHelper
  def task_name
    self.class.top_level_description
  end

  def task_path
    "lib/tasks/#{task_name.split(":").first}"
  end

  def invoke_task(name)
    rake = Rake::Application.new
    Rake.application = rake
    Rake.application.rake_require(task_path, [Rails.root.to_s], loaded_files_excluding_current_rake_file)
    Rake::Task.define_task(:environment)

    rake.invoke_task(name)
  end

  def loaded_files_excluding_current_rake_file
    $LOADED_FEATURES.reject { |file| file == Rails.root.join("#{task_path}.rake").to_s }
  end
end
