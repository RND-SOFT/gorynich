ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('dummy/config/environment.rb', __dir__)
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'

# это надо для прогрузки классов и корректного рассчёта SimpleCov. Без него мы теряем целый процент!!
Rails.application.eager_load!
require 'gorynich'

[].tap do |r_files|
  r_files += Dir[Rails.root.join('spec', 'support', 'helpers', '**', '*.rb')]

  r_files.each { |f| require f }
end
