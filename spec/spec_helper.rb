require 'rspec/retry'
require 'shoulda/matchers'
require 'simplecov'
require 'simplecov-console'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter
])

unless %w[F FALSE 0].include? ENV['COVERAGE'].to_s.upcase
  SimpleCov.start 'rails' do
    add_filter do |source_file|
      # Первой строчкой должен быть коммент "skip coverage"
      source_file.src.first&.match(/skip coverage/)
    end
  end

  if ENV['TEST_ENV_NUMBER'] # parallel specs
    SimpleCov.at_exit do
      result = SimpleCov.result
      result.format! if ParallelTests.number_of_running_processes <= 1
    end
  end
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end
