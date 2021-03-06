
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "s3_assets/version"

Gem::Specification.new do |spec|
  spec.name          = "s3_assets"
  spec.version       = S3Assets::VERSION
  spec.authors       = ["Amit Chaudhary"]
  spec.email         = ["chaudharyamitiit2007@gmail.com"]

  spec.summary       = %q{Common package build up for storing s3 assets reference.}
  spec.description   = %q{You can store s3 assets very easity using this}
  spec.homepage      = "https://github.com/chaudhary/s3_assets"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #
  #   spec.metadata["homepage_uri"] = spec.homepage
  #   spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #   spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "mongoid", '~> 6.4', '>= 6.4.2'
  spec.add_development_dependency "carrierwave", '~> 1.2', '>= 1.2.3'
  spec.add_development_dependency "carrierwave-mongoid", '~> 1.1', '>= 1.1.0'
  spec.add_development_dependency "fog-aws", '~> 2.0', '>= 2.0.1'
  spec.add_development_dependency "fog", '~> 2.0', '>= 2.0.0'
  spec.add_development_dependency "delayed_job", '~> 4.1', '>= 4.1.5'
  spec.add_development_dependency "delayed_job_mongoid", '~> 2.3', '>= 2.3.0'
end
