require_relative "lib/nursebot/version"

GITHUB_URL = "https://github.com/simpledotorg/simple-server"

Gem::Specification.new do |spec|
  spec.name        = "nursebot"
  spec.version     = Nursebot::VERSION
  spec.authors     = ["Owajigbanam Ogbuluijah"]
  spec.email       = ["igbanam@rtsl.org"]
  spec.homepage    = GITHUB_URL
  spec.summary     = "Simple Conversation Bot"
  spec.description = "A bot which holds conversation on behalf of the HealthCare Worker"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/simpledotorg/simple-server/blob/master/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.7", ">= 6.1.7.10"
end
