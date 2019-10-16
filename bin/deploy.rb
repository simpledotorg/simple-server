#!/usr/bin/env ruby
#
# ---- This intends to:
#
# * Be a zero-dependency script to automate Simple's deployment workflow
# * Not be tied to Simple's domain in any way
# * Be functional on Linux and OS X
#
# ---- Run this command to get instructions on how to use this script:
# ± bin/deploy.rb help
#
require 'pathname'

class DeployError < StandardError
end

class Deploy
  DEPLOY_DIR = 'config/deploy/*'

  ENVIRONMENTS_SUPPORTED = Dir
                             .glob(DEPLOY_DIR)
                             .map { |file| Pathname.new(file).basename('.rb').to_s }

  DIRS_WITH_CRITICAL_CHANGES = {
    'db/' => 'Holds all the database migrations',
    'lib/' => "Holds all the rake tasks for data migrations",
    '.env.development' => "Holds all application configs",
    'config/' => "Holds all service / third-party configs"
  }

  attr_reader :current_environment,
              :tag_to_deploy,
              :changelog,
              :last_deployed_sha

  def initialize(current_environment:, tag_to_deploy:)
    print_usage_and_exit unless check_current_git_branch == 'master'
    print_usage_and_exit if current_environment.nil? || current_environment == 'help'

    unless ENVIRONMENTS_SUPPORTED.include?(current_environment)
      $stderr.puts "Unknown environment '#{current_environment}'"
      $stderr.puts "Supported environments: #{ENVIRONMENTS_SUPPORTED.sort.join(', ')}"
      $stderr.puts ""
      print_usage_and_exit
    end

    print_usage_and_exit if (current_environment == 'production' && tag_to_deploy.nil?)

    @tag_to_deploy = tag_to_deploy
    @current_environment = current_environment
  end


  def start
    steps = deploy_steps.sort
    final_step = (steps.size - 1)

    steps.each_with_index do |(_, step), step_num|
      next if step.key?(:skip_for) && step[:skip_for].include?(current_environment)

      wrap_step_in_box(step[:msg]) do
        step[:action].call
      end

      unless step_num == final_step
        print_newlines(n: 3)
        sleep 1
      end
    end
  end

  private

  def deploy_steps
    {
      1 => { msg: 'Printing CHANGELOG...',
             action: -> { print_changelog } },

      2 => { msg: 'Checking for changes in critical files / directories...',
             action: -> { find_changes_in_files(DIRS_WITH_CRITICAL_CHANGES.keys) } },

      3 => { msg: 'Creating release tag...',
             action: -> { create_and_push_release_tag(current_date) },
             skip_for: ['sandbox', 'qa', 'production'] },

      4 => { msg: 'Deploying...',
             action: -> { deploy } }
    }
  end

  def print_changelog
    puts <<-CHANGELOG
Use this commit history to document CHANGELOG.md or share it in appropriate release channels.
This is generated from the diff between #{last_deployed_sha}..HEAD

#{changelog.empty? ? "No changelog could be generated." : changelog}
    CHANGELOG
  end

  def find_changes_in_files(list_of_files)
    list_of_files.each_with_index do |file, idx|
      puts "Looking for changes in #{file}"

      changes = changes_in_file(file)
      if changes.empty?
        puts "Found no change in #{file}. Moving ahead..."
      else
        puts "Found changes in #{file}."
        puts changes
        prompt_for_confirmation('Please check the diff in the file and confirm', ['y', 'Y'], 32)
      end

      unless idx == (list_of_files.size - 1)
        print_newlines(n: 1)
      end
    end
  end

  def create_and_push_release_tag(date)
    unless @tag_to_deploy.nil?
      puts "Skipping, since you have already specified a tag."
      return
    end

    existing_tag =
      find_existing_release_tags(date)

    @tag_to_deploy =
      if existing_tag.nil? || existing_tag.empty?
        puts "Putting up a release tag #{generate_release_tag_value(date)} with a CHANGELOG..."
        generate_release_tag_value(date)
      else
        puts "Release tag for current date already exists: #{existing_tag}. Creating an incremental release..."

        new_release_number = extract_release_tag_info(existing_tag)[:release_num] += 1
        generate_release_tag_value(date, new_release_number)
      end

    # create tag
    execute_safely("git tag -a #{@tag_to_deploy} -m \"#{changelog}\"", confirm: true)
    puts "Created tag #{@tag_to_deploy}."

    # push tag
    puts "Pushing tag #{@tag_to_deploy} to remote..."
    execute_safely("git push origin refs/tags/#{@tag_to_deploy}", confirm: true)
  end

  def print_usage_and_exit
    $stderr.puts "Usage: bin/deploy <environment> [tag-to-deploy]"
    $stderr.puts ""
    $stderr.puts "Note: tag-to-deploy is required to deploy to production"
    $stderr.puts "Note: Make sure you are locally on the latest master branch"
    exit 1
  end

  def last_deployed_sha
    @last_deployed_sha ||=
      execute_safely("cap #{current_environment} deploy:get_latest_deployed_sha",
                     { 'CONFIRM' => 'false' })
        .strip
        .split("\n")
        .last
  end

  def changelog
    @changelog ||= execute_safely("git log #{last_deployed_sha}..HEAD --oneline --decorate=no")
                     .strip
                     .split("\n")
                     .map { |line| line.match(/\s(.*)/)&.captures&.last }
                     .reject { |line| line =~ /^Merge/ }
                     .compact
                     .join("\n")
  end

  def changes_in_file(file)
    execute_safely("git diff #{last_deployed_sha}..HEAD #{file}")
  end

  def find_existing_release_tags(date)
    tag_glob = date + '*'
    execute_safely("git tag -l \"#{tag_glob}\"").split("\n").last
  end

  def generate_release_tag_value(date, release_number = 1)
    "#{date}-#{release_number}"
  end

  def current_date
    Time.current.strftime("%Y-%m-%d")
  end

  def deploy
    puts "#{@tag_to_deploy || 'master'} to '#{current_environment}'."
    puts "Please 'tail -f log/capistrano.log' for more info."
    execute_safely("bundle exec cap #{current_environment} deploy",
                   { 'BRANCH' => @tag_to_deploy, 'CONFIRM' => 'false' },
                   confirm: true)
  end

  def wrap_step_in_box(step_name, &blk)
    puts "#{step_name}"
    puts "+#{"-" * (step_name.size - 1)}+"
    yield(blk)
    puts colorize("✔".encode('utf-8'), 32)
  rescue DeployError
    puts colorize("✗".encode('utf-8'), 31)
    exit 1
  ensure
    puts "+#{"-" * (step_name.size - 1)}+"
  end

  def execute_safely(cmd, env_vars = {}, confirm: false)
    prompt_for_confirmation('Confirm before proceeding', ['y', 'Y'], 32) if confirm

    env_vars.each { |env_var, value| ENV[env_var] = value } unless env_vars.empty?
    output = `#{cmd}`
    raise DeployError if $?.exitstatus > 0
    output
  end

  #
  # helpful color codes:
  #
  # red: 31
  # green: 32
  # blue: 34
  #
  def colorize(content, color_code)
    "\e[#{color_code}m#{content}\e[0m"
  end

  def extract_release_tag_info(tag)
    matches = tag.match(release_tag_regex).captures

    {
      year: matches[0],
      month: matches[1],
      day: matches[2],
      release_num: matches[3].to_i
    }
  end

  def release_tag_regex
    %r{([0-9]{4})-([0][0-9]|[1][0-2])-([0][0-9]|[1][0-9]|[2][0-9]|[3][0-1])-([0-9]{1,})}
  end

  def prompt_for_confirmation(msg, prompt_codes, color)
    printf colorize("#{msg}: [#{prompt_codes.join(',')}] ", color)
    prompt = STDIN.gets.chomp
    exit 1 unless prompt_codes.include?(prompt)
  end

  def print_newlines(n: 3)
    puts "\n" * n
  end

  def check_current_git_branch
    execute_safely('git rev-parse --abbrev-ref HEAD').strip
  end
end

Deploy
  .new(current_environment:
         ARGV[0],
       tag_to_deploy:
         ARGV[1])
  .start
