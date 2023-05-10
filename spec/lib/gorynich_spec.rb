RSpec.describe Gorynich do
  subject(:gorynich) { described_class }
  let(:default_database) { gorynich.instance.database('default').fetch('database') }

  let(:tenant) { 'local1' }
  let(:tenant_database) { gorynich.instance.database(tenant).fetch('database') }

  def current_database
    ActiveRecord::Base.connection.current_database
  end

  def current_tenant
    gorynich::Current.tenant
  end

  RSpec.shared_context 'Within Tenant' do |method:|
    around do |ex|
      gorynich.send(method, tenant) do
        ex.run
      end
    end
  end

  context '::configuration' do
    it { is_expected.to have_attributes(configuration: gorynich::Configuration) }
  end

  context '::instance' do
    it { is_expected.to have_attributes(instance: gorynich::Config) }
  end

  context '::switcher' do
    it { is_expected.to have_attributes(switcher: gorynich::Switcher) }
  end

  context '::with_database' do
    subject(:actual_database) { current_database }

    it { is_expected.to eq default_database }

    it_behaves_like 'Within Tenant', method: 'with_database' do
      it do
        is_expected.to eq tenant_database
      end
    end
  end

  context '::with_current' do
    subject(:actual_tenant) { current_tenant }

    it { is_expected.to be_nil }

    it_behaves_like 'Within Tenant', method: 'with_current' do
      it do
        is_expected.to eq tenant
      end
    end
  end

  context '::with' do
    it { expect(current_database).to eq(default_database) }
    it { expect(current_tenant).to be_nil }

    it_behaves_like 'Within Tenant', method: 'with' do
      it do
        expect(current_database).to eq(tenant_database)
      end

      it do
        expect(current_tenant).to eq(tenant)
      end
    end
  end

  context '::with_each_tenant' do
    describe 'when without except' do
      it { expect(current_database).to eq(default_database) }
      it { expect(current_tenant).to be_nil }

      it do
        gorynich.with_each_tenant do |t|
          expect(gorynich.instance.tenants).to include(t.tenant)
        end
      end

      it do
        gorynich.with_each_tenant do |t|
          expect(current_database).to eq(gorynich.instance.database(t.tenant).fetch('database'))
        end
      end

      it do
        gorynich.with_each_tenant do |t|
          expect(current_tenant).to eq(t.tenant)
        end
      end
    end
  end
end
