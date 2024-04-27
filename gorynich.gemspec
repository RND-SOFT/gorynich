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
  spec.add_dependency 'railties', '>= 6.1'

  spec.test_files = Dir['spec/**/*']
end

