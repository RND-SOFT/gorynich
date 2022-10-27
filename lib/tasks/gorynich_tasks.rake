desc 'Gorynich console'
task gc: :environment do
  require 'irb'
  require 'irb/completion'
  require 'rails/commands/console/console_command'
  Gorynich.with(ENV.fetch('TENANT', Gorynich.instance.default)) do
    Rails::Console.start(Rails.application)
  end
end

namespace :gc do
  namespace :db do
    desc 'Create static database.yml'
    task prepare: :environment do
      database_config = Rails.root.join('config', 'database.yml')

      File.open(database_config, 'w+') do |f|
        f.write('<%= Gorynich.instance.database_config %>')
        f.rewind

        database_result = ::ERB.new(f.read).result
        f.rewind
        f.write(database_result)
      end
    end
  end
end
