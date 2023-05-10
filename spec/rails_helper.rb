ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('dummy/config/environment.rb', __dir__)
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
Rails.application.eager_load!
require 'gorynich'
