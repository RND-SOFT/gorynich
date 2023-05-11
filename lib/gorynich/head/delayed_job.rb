# Do not require this until want to use DelayedJob

module Gorynich
  module Head
    class DelayedJob < ::Delayed::Plugin

      callbacks do |lifecycle|
        lifecycle.around(:execute) do |*_args, &block|
          Gorynich.with(Gorynich.instance.default) do |current|
            if ::Delayed::Worker.logger.respond_to?(:tagged)
              ::Delayed::Worker.logger.tagged(tenant: current.tenant) { block.call }
            else
              block.call
            end
          end
        end
      end

    end
  end
end

