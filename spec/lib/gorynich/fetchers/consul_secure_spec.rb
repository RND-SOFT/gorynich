RSpec.describe Gorynich::Fetchers::ConsulSecure do
  let(:storage) { Faker::Lorem.word }
  let(:file_path) { "#{RSPEC_ROOT}/fixtures/fetchers/file_config.yml" }
  let(:file_like_object) { double("file like object") }

  context '#fetch' do
    let(:consul_host) { Faker::Internet.url }
    let(:consul_opts) { { http_addr: consul_host } }

    def consul_request(response, code = 200)
      stub_request(:get, "#{consul_host}/v1/kv/#{storage}?recurse=true")
        .to_return(
          status: code,
          body: response
        )
    end

    subject { described_class.new(storage: storage, file_path: file_path, **consul_opts) }

    describe 'when consul return data' do
      let(:response) { [{ 'Key' => "#{storage}/test_key", 'Value' => Base64.encode64('test') }].to_json }

      before(:each) do
        consul_request(response)
      end

      it do
        allow(File).to receive(:open).with(file_path, 'w').and_return(file_like_object)
        expect(subject.fetch).to eq({ 'test_key' => 'test' })
      end
    end

    describe 'when http error' do
      before(:each) do
        consul_request([], 500)
      end

      it do
        result = subject.fetch
        expect(result.class).to eq(Hash)
        expect(result).to include('development', 'test')
      end
    end
  end
end
