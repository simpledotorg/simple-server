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
  }

  attr_reader :current_environment,
              :tag_to_deploy,
              :changelog,
              :last_deployed_sha

  def initialize(current_environment:, tag_to_deploy:)
    print_usage_and_exit if current_environment.nil? || current_environment == 'help'

    unless ENVIRONMENTS_SUPPORTED.include?(current_environment)
      $stderr.puts "Unknown environment '#{current_environment}'"
      $stderr.puts "Supported environments: #{ENVIRONMENTS_SUPPORTED.sort.join(', ')}"
      $stderr.puts ""
      print_usage_and_exit
    end

    print_usage_and_exit if (current_environment == 'production' && tag.nil?)

    @tag_to_deploy = tag_to_deploy
    @current_environment = current_environment
    @last_deployed_sha = last_deployed_sha
    @changelog = changelog
  end

  def start
    steps = deploy_steps.sort
    final_step = (steps.size - 1)

    steps.each_with_index do |(_, step), step_num|
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
             action: -> { create_and_push_release_tag(current_date) } },

      4 => { msg: 'Deploying...',
             action: -> { deploy } }
    }
  end

  def print_changelog
    puts <<-CHANGELOG
Use this commit history to document CHANGELOG.md or share it in appropriate release channels.
This is generated from the diff between #{last_deployed_sha}..HEAD

#{changelog}
    CHANGELOG
  end

  def find_changes_in_files(list_of_files)
    list_of_files.each do |file|
      puts "Looking for changes in #{file}"

      if change_in_file?(file)
        puts "Found changes in #{file}. Exiting..."
        exit 1
      else
        puts "Found no change in #{file}. Moving ahead..."
      end

      print_newlines(n: 1)
    end
  end

  def create_and_push_release_tag(date)
    existing_tag =
      find_existing_release_tags(date)

    @tag_to_deploy ||=
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
    execute_safely("git push --dry-run origin refs/tags/#{@tag_to_deploy}", confirm: true)
  end

  def print_usage_and_exit
    $stderr.puts "Usage: bin/deploy <environment> [tag-to-deploy]"
    $stderr.puts ""
    $stderr.puts "Note: tag-to-deploy is required to deploy to production"
    exit 1
  end

  def last_deployed_sha
    execute_safely("cap #{current_environment} deploy:get_latest_deployed_sha")
      .strip
  end

  def changelog
    execute_safely("git log #{last_deployed_sha}..HEAD --oneline --decorate=no | cut -c10- | grep -v '^Merge'")
      .strip
  end

  def change_in_file?(file)
    word_count = execute_safely("git diff #{last_deployed_sha}..HEAD #{file} | wc -l").to_i
    return true if word_count > 0
    false
  end

  def find_existing_release_tags(date)
    tag_glob = date + '*'
    execute_safely("git tag -l \"#{tag_glob}\"").split("\n").last
  end

  def generate_release_tag_value(date, release_number = 1)
    "#{date}-#{release_number}"
  end

  def current_date
    Time.now.strftime("%Y-%m-%d")
  end

  def deploy
    execute_safely("cap #{current_environment} deploy --dry-run",
                   { 'BRANCH' => @tag_to_deploy })
  end

  def wrap_step_in_box(step_name, &blk)
    puts "#{step_name}"
    puts "+---------------------------------------+"
    yield(blk)
    puts colorize("\u2713".encode('utf-8'), 32)
  rescue DeployError
    puts colorize("\u2717".encode('utf-8'), 31)
    exit 1
  ensure
    puts "+---------------------------------------+"
  end

  def execute_safely(cmd, env_vars = {}, confirm: false)
    prompt_for_confirmation if confirm
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

  def prompt_for_confirmation
    printf colorize("Press 'y/Y' to continue: ", 34)
    prompt = STDIN.gets.chomp
    exit 1 unless ['y', 'Y'].include?(prompt)
  end

  def print_newlines(n: 3)
    n.times { send(:puts) }
  end
end

Deploy
  .new(current_environment:
         ARGV[0],
       tag_to_deploy:
         ARGV[1])
  .start
