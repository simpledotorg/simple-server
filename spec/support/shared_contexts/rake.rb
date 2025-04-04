require "rake"

shared_context "rake" do
  let(:rake) { Rake::Application.new }
  let(:task_name) { self.class.top_level_description }
  let(:task_path) { "lib/tasks/#{task_name.split(":").first}" }
  subject { rake[task_name] }

  def all_but_rake_file
    $".reject do |file|
      file == Rails.root.join("#{task_path}.rake").to_s
    end
  end

  before do
    Rake.application = rake
    Rake.application.rake_require(task_path, [Rails.root.to_s], all_but_rake_file)
    Rake::Task.define_task(:environment)
  end
end
