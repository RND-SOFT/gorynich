require 'rails_helper'

RSpec.describe Gorynich::Fetchers::Consul do
  let(:storage) { Faker::Lorem.word }

  context '#storage' do
    subject { described_class.new(storage: storage) }

    it do
      expect(subject.storage).to eq(storage)
    end
  end

  context '#consul_opts' do
    let(:consul_opts) { { Faker::Lorem.word.to_sym => Faker::Lorem.word } }

    subject { described_class.new(storage: storage, **consul_opts) }

    it do
      expect(subject.consul_opts).to eq(consul_opts)
    end
  end

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

    subject { described_class.new(storage: storage, **consul_opts) }

    describe 'when consul return data' do
      let(:response) { [{ 'Key' => "#{storage}/test_key", 'Value' => Base64.encode64('test') }].to_json }

      before(:each) do
        consul_request(response)
      end

      it do
        expect(subject.fetch).to eq({ 'test_key' => 'test' })
      end
    end

    describe 'when http error' do
      before(:each) do
        consul_request([], 500)
      end

      it do
        expect { subject.fetch }.to raise_error(Diplomat::UnknownStatus)
      end
    end
  end
end
