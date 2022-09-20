class TestJob < ApplicationJob
  def perform
    puts "==============================#{Gorynich::Current.tenant}===================================="
  end
end
