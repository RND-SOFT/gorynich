# rubocop:disable Layout/LineLength
module Gorynich
  module Head
    class DelayedJob < ::Delayed::Plugin
      callbacks do |lifecycle|
        lifecycle.around(:execute) do |*_args, &block|
          Gorynich.with(Gorynich.instance.default) do |current|
            ::Delayed::Worker.logger.tagged("Gorynich(#{current.tenant})") do
              ::Delayed::Worker.logger.debug do
                current_database = ::ActiveRecord::Base.connection.execute('SELECT current_database();').first['current_database']
                "HOOK[execute] on: actual_database #{current_database}"
              end
              block.call
            end
          end
        end

        lifecycle.around(:loop) do |*_args, &block|
          Gorynich.with(Gorynich.instance.default) do |_current|
            ::Delayed::Worker.logger.debug do
              current_database = ::ActiveRecord::Base.connection.execute('SELECT current_database();').first['current_database']
              "HOOK[loop] on: actual_database #{current_database}"
            end
            block.call
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
