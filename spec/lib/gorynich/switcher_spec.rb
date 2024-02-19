RSpec.describe Gorynich::Switcher do
  let(:config) do
    {
      'test' => {
        'default' => {
          'db_config' => {},
          'secrets'   =>   {}
        }
      }
    }
  end
  let(:fetcher) { HashFetcher.new(**config) }
  let(:gorynich_config) { Gorynich::Config.new(fetcher: fetcher) }

  subject { described_class.new(config: gorynich_config) }

  describe '#with_database' do
    context 'when tenant not found' do
      it do
        expect(::ActiveRecord::Base).to receive(:connected_to).with(role: :test).and_raise(
          ::ActiveRecord::ConnectionNotEstablished
        )
        expect { subject.with_database('test') }.to raise_error(Gorynich::TenantNotFound)
      end
    end

    context 'when have tenant but ConnectionNotEstablished' do
      before(:each) do
        allow(::Gorynich).to receive(:instance).and_return(gorynich_config)
      end

      it do
        expect(::ActiveRecord::Base).to receive(:connected_to).with(role: :default).and_raise(
          ::ActiveRecord::ConnectionNotEstablished
        )
        expect_any_instance_of(
          ::ActiveRecord::ConnectionAdapters::ConnectionHandler
        ).to receive(:establish_connection).with(
          gorynich_config.database('default'), role: :default
        )
        expect(::ActiveRecord::Base).to receive(:connected_to)
        subject.with_database('default')
      end
    end
  end
end
