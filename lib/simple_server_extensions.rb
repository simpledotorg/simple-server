# frozen_string_literal: true

module SimpleServerExtensions
  # We first check for the REVISION file that Capistrano deploys for us, otherwise we fall
  # back to using git to grab it from the live repo (for dev/test environments)
  def self.determine_git_ref
    if Rails.root.join("REVISION").exist?
      Rails.root.join("REVISION").read
    else
      `git rev-parse HEAD`.chomp
    end
  end

  GIT_REF = determine_git_ref

  def env
    ActiveSupport::StringInquirer.new(SIMPLE_SERVER_ENV)
  end

  def git_ref(short: false)
    short ? GIT_REF[0..6] : GIT_REF
  end

  def github_url
    "https://github.com/simpledotorg/simple-server/commit/#{git_ref}"
  end
end

# Add on to the top level application constant to make things easy
SimpleServer.extend SimpleServerExtensions
