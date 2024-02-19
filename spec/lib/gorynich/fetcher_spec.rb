RSpec.describe Gorynich::Fetcher do
  let(:file_path) { "#{RSPEC_ROOT}/fixtures/fetchers/file_config.yml" }
  let(:consul_storage) { Faker::Lorem.word }
  let(:consul_host) { Faker::Internet.url }
  let(:consul_opts) { { http_addr: consul_host } }
  let(:consul_response) { [{ 'Key' => "#{consul_storage}/test_key", 'Value' => Base64.encode64('test') }].to_json }

  def consul_request(response, code = 200)
    stub_request(:get, "#{consul_host}/v1/kv/#{consul_storage}?recurse=true")
      .to_return(
        status: code,
        body: response
      )
  end

  context '#new' do
    let(:fetcher) { Gorynich::Fetchers::File.new(file_path: file_path) }
    let(:namespace) { Faker::Lorem.word }
    let(:cache_expiration) { Faker::Number.between(from: 1, to: 10).minutes }

    describe 'when from config' do
      before(:each) do
        Gorynich.configure do |config|
          config.fetcher = fetcher
          config.namespace = namespace
          config.cache_expiration = cache_expiration
        end
      end

      subject { described_class.new }

      it do
        expect(subject.fetcher).to eq(fetcher)
        expect(subject.namespace).to eq(namespace)
        expect(subject.cache_expiration).to eq(cache_expiration)
      end
    end

    describe 'when from initialize' do
      before(:each) { Gorynich.reset }

      subject { described_class.new(fetcher: fetcher, namespace: namespace, cache_expiration: cache_expiration) }

      it do
        expect(subject.fetcher).to eq(fetcher)
        expect(subject.namespace).to eq(namespace)
        expect(subject.cache_expiration).to eq(cache_expiration)
      end
    end
  end

  context '#fetch' do
    before(:each) { Gorynich.configuration.cache.clear }

    describe 'when no fetcher' do
      subject { described_class.new }

      it do
        expect { subject.fetch }.to raise_error(Gorynich::Error)
      end
    end

    describe 'when one fetcher' do
      let(:fetcher) { Gorynich::Fetchers::File.new(file_path: file_path) }

      subject { described_class.new(fetcher: fetcher) }

      it do
        result = subject.fetch
        expect(result.class).to eq(Hash)
        expect(result).to include('development', 'test')
      end
    end

    describe 'when some fetchers' do
      let(:file_fetcher) { Gorynich::Fetchers::File.new(file_path: file_path) }
      let(:consul_fetcher) { Gorynich::Fetchers::Consul.new(storage: consul_storage, **consul_opts) }

      subject { described_class.new(fetcher: [consul_fetcher, file_fetcher]) }

      describe 'when consul fetch success' do
        before(:each) { consul_request(consul_response) }

        it do
          expect(subject.fetch).to eq({ 'test_key' => 'test' })
        end
      end

      describe 'when consul fetch failed' do
        before(:each) do
          Gorynich.configuration.cache = ActiveSupport::Cache::MemoryStore.new
          consul_request(consul_response, 500)
        end

        it do
          expect(subject.fetch).to include('development', 'test')
        end
      end
    end
  end

  context 'fetch with cache' do
    let(:fetcher) { Gorynich::Fetchers::File.new(file_path: file_path) }

    subject { described_class.new(fetcher: fetcher) }

    it do
      expect(subject.fetch).to include('development', 'test')
      expect(Gorynich.configuration.cache.exist?(%i[gorynich fetcher fetch])).to be(true)
    end
  end

  describe '#reset' do
    let(:fetcher) { Gorynich::Fetchers::File.new(file_path: file_path) }

    subject { described_class.new(fetcher: fetcher) }

    it do
      subject.fetch
      expect(Gorynich.configuration.cache.exist?(%i[gorynich fetcher fetch])).to be(true)

      subject.reset
      expect(Gorynich.configuration.cache.exist?(%i[gorynich fetcher fetch])).to be(false)
    end
  end
end
