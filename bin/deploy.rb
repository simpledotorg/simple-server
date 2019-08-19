#!/usr/bin/env ruby

#
# * take environment as a command line param
#
# * fetched the last release tag from git [PROD]
# git tag | sort -r | grep '^20..-..-..-..*' | head -n1
#
# * get all the commit messages since that tag [PROD]
# git log $(git tag | sort -r | grep '^20..-..-..-..*' | head -n1)..HEAD --oneline --decorate=no | cut -c10- | grep -v '^Merge'
#
# * print the above command out for copy-pasta in changelog.md [PROD/SBX]
#
# * figure out if there's a diff in: [PROD/SBX]
# [git diff HEAD..HEAD | grep index]
# * git diff 2019-08-08-1..HEAD db/ | wc -l
# * git diff 2019-08-08-1..HEAD lib/ | wc -l
# * git diff 2019-08-08-1..HEAD .env.development | wc -l
# * git diff 2019-08-08-1..HEAD config/ | wc -l
#
# * if no tag exists for today, create a new one: [PROD]
# date +'%Y-%m-%d-1'
#
# * if tag does exist, create a new one with an incremented release number [PROD]
#
# * add new tag to git with the changelog as the message [PROD]
#
# * deploy to <env>
# BRANCH=<new-tag> cap production deploy [PROD]
# cap <env> deploy [SBX/QA/etc]
#

require 'pathname'

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

  attr_reader :current_environment, :tag_to_deploy

  def initialize(current_environment:, tag_to_deploy:)
    print_usage_and_exit if current_environment.nil?

    unless ENVIRONMENTS_SUPPORTED.include?(current_environment)
      $stderr.puts "Unknown environment '#{current_environment}'"
      $stderr.puts "Supported environments: #{ENVIRONMENTS_SUPPORTED.sort.join(', ')}"
      $stderr.puts ""
      print_usage_and_exit
    end

    print_usage_and_exit if (current_environment == 'production' && tag.nil?)

    @tag_to_deploy = tag_to_deploy
    @current_environment = current_environment
  end

  def start
    last_deployed_sha = last_deployed_sha(current_environment)
    generate_changelog(last_deployed_sha)

    wrap_step_in_box("Printing CHANGELOG...") { print_changelog(last_deployed_sha) }

    wrap_step_in_box('Checking for changes in critical files / directories...') {
      find_changes_in_files(last_deployed_sha,
                            DIRS_WITH_CRITICAL_CHANGES.keys)
    }

    wrap_step_in_box("Creating release tag...") { create_git_release_tag(current_date, @changelog) }
  end

  private

  def print_usage_and_exit
    $stderr.puts "Usage: bin/deploy <environment> [tag-to-deploy]"
    $stderr.puts ""
    $stderr.puts "Note: tag-name is required to deploy to production"
    exit 1
  end

  def print_changelog(sha)
    puts <<-CHANGELOG
Use this commit history to document CHANGELOG.md or share it in appropriate release channels.

Between #{sha}..HEAD

#{@changelog}
    CHANGELOG
  end

  def generate_changelog(sha)
    @changelog ||= `git log #{sha}..HEAD --oneline --decorate=no | cut -c10- | grep -v '^Merge'`.strip
  end

  def last_deployed_sha(env)
    `cap #{env} deploy:get_latest_deployed_sha`.strip
  end

  def find_changes_in_files(sha, list_of_files)
    list_of_files.each do |file|
      puts "Looking for any changes in #{file}"

      if change_in_file?(sha, file)
        puts "Found changes in #{file}. Exiting..."
        exit 1
      else
        puts "Found no change in #{file}. Moving ahead..."
      end

      puts
    end
  end

  def change_in_file?(sha, file)
    word_count = `git diff #{sha}..HEAD #{file} | wc -l`.to_i
    return true if word_count > 0
    false
  end

  def release_tag_exists?(time)
    tag_glob = time + '*'
    word_count = `git tag -l "#{tag_glob}" | wc -l`.to_i
    return true if word_count > 0
    false
  end

  def create_git_release_tag(date, changelog)
    if release_tag_exists?(date)
      puts "There is already a tag with a date: #{date}. Creating an incremental release..."
      # create an incremental release tag
    else
      puts "Putting up a release tag #{create_new_release_tag(date)} with a CHANGELOG..."
      `git tag -a #{create_new_release_tag(date)} -m "#{changelog}"`
    end
  end

  def create_new_release_tag(date, release_number = nil)
    "#{date}-#{release_number || 1}"
  end

  def current_date
    Time.now.strftime("%Y-%m-%d")
  end

  def deploy(env)
    # run cap deploy for the appropriate env
  end

  def wrap_step_in_box(step_name, &blk)
    puts

    puts "#{step_name}"
    puts "+---------------------------------------+"
    yield(blk)
    puts "+---------------------------------------+"

    puts "\n\n\n"
  end
end

deploy = Deploy.new(current_environment: ARGV[0], tag_to_deploy: ARGV[1])
deploy.start
