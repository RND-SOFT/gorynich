require 'rails_helper'

RSpec.describe Gorynich do
  context '::configuration' do
    it do
      expect(described_class.configuration.class).to eq(described_class::Configuration)
    end
  end

  context '::instance' do
    it do
      expect(described_class.instance.class).to eq(described_class::Config)
    end
  end

  context '::switcher' do
    it do
      expect(described_class.switcher.class).to eq(described_class::Switcher)
    end
  end

  context '::with_database' do
    it do
      expect(ActiveRecord::Base.connection.current_database).to eq(
        described_class.instance.database('default').fetch('database')
      )

      described_class.with_database('local1') do
        expect(ActiveRecord::Base.connection.current_database).to eq(
          described_class.instance.database('local1').fetch('database')
        )
      end
    end
  end

  context '::with_current' do
    it do
      expect(described_class::Current.tenant).to be_nil

      described_class.with_current('local1') do
        expect(described_class::Current.tenant).to eq('local1')
      end
    end
  end

  context '::with' do
    it do
      expect(ActiveRecord::Base.connection.current_database).to eq(
        described_class.instance.database('default').fetch('database')
      )
      expect(described_class::Current.tenant).to be_nil

      described_class.with('local1') do
        expect(ActiveRecord::Base.connection.current_database).to eq(
          described_class.instance.database('local1').fetch('database')
        )
        expect(described_class::Current.tenant).to eq('local1')
      end
    end
  end
end
