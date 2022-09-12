desc 'Gorynich console'
task gc: :environment do
  require 'irb'
  require 'irb/completion'
  require 'rails/commands/console/console_command'
  Gorynich.with(ENV.fetch('TENANT', Gorynich.instance.default)) do
    Rails::Console.start(Rails.application)
  end
end
