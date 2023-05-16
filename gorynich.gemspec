$:.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'gorynich/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'gorynich'
  spec.version     =
    if ENV['BUILDVERSION'].to_i > 0
      "#{Gorynich::VERSION}.#{ENV['BUILDVERSION'].to_i}"
    else
      Gorynich::VERSION
    end
  spec.authors     = ['Poliev Alexey', 'Samoilenko Yuri']
  spec.email       = ['apoliev@rnds.pro', 'kinnalru@gmail.com']
  spec.summary     = 'Multitenancy for Rails and subsystems'
  spec.description = 'Multitenancy for Rails including ActiveRecord, ActionCable, ActiveJob and other subsystems'
  spec.homepage    = 'https://github.com/RND-SOFT/gorynich'
  spec.license     = 'MIT'

  spec.files = Dir['{config}/**/*', '{lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'diplomat', '~> 2'
  spec.add_dependency 'rails', '>= 6.1'

  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'faker'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'racc'
  spec.add_development_dependency 'rspec-collection_matchers'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec-retry'
  spec.add_development_dependency 'rspec-set'
  spec.add_development_dependency 'shoulda-callback-matchers'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-cobertura'
  spec.add_development_dependency 'simplecov-console'
  spec.add_development_dependency 'tzinfo-data'
  spec.add_development_dependency 'webmock'

  spec.test_files = Dir['spec/**/*']
end

