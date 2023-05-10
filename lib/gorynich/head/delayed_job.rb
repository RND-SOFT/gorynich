# Do not require this until want to use DelayedJob

module Gorynich
  module Head
    class DelayedJob < ::Delayed::Plugin
      callbacks do |lifecycle|
        lifecycle.around(:execute) do |*_args, &block|
          Gorynich.with(Gorynich.instance.default) do |current|
            ::Delayed::Worker.logger.tagged(tenant: current.tenant) do
              block.call
            end
          end
        end

        lifecycle.around(:loop) do |*_args, &block|
          Gorynich.with(Gorynich.instance.default) do |_current|
            block.call
          end
        end
      end
    end
  end
end
