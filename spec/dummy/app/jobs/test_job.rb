class TestJob < ApplicationJob
  def perform
    puts "==============================#{Gorynich::Current.tenant}===================================="
    User.first.update!(username: SecureRandom.hex)
  end
end
