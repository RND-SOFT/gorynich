$:.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'gorynich/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'gorynich'
  spec.version     = Gorynich::VERSION
  spec.authors     = ['Poliev Alexey']
  spec.email       = ['apoliev@rnds.pro']
  spec.summary     = 'Gem for switching databases'
  spec.description = 'Gem for switching databases for multitenancy apps'
  spec.homepage    = 'https://rnds.pro'

  spec.files = Dir['{lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'rails', '~> 6.1'
  spec.add_dependency 'diplomat', '~> 2'

  spec.add_development_dependency 'pg'
end
