require 'spec_helper'

SingleCov.covered! uncovered: 1

describe Docker::Task do
  describe '.all' do
    subject { described_class }

    context 'when the HTTP response is not a 200' do
      before do
        Docker.options = { :mock => true }
        Excon.stub({ :method => :get }, { :status => 500 })
      end
      after do
        Excon.stubs.shift
        Docker.options = {}
      end

      it 'raises an error' do
        expect { subject.all }
            .to raise_error(Docker::Error::ServerError)
      end
    end

    context 'when the HTTP response is a 200' do
      let(:service) {
        Docker::Service.create({ 'TaskTemplate' => { 'ContainerSpec' => { 'Image' => 'debian:wheezy' } } })
      }
      before { service }
      after { service.remove }

      it 'materializes each Task into a Docker::Task' do
        expect(subject.all(:all => true)).to be_all { |task|
          task.is_a?(Docker::Task)
        }
        expect(subject.all(:all => true).length).to_not be_zero
      end
    end
  end

  describe '.get' do
    subject { described_class }

    context 'when the HTTP response is not a 200' do
      before do
        Docker.options = { :mock => true }
        Excon.stub({ :method => :get }, { :status => 500 })
      end
      after do
        Excon.stubs.shift
        Docker.options = {}
      end

      it 'raises an error' do
        expect { subject.get('randomID') }
            .to raise_error(Docker::Error::ServerError)
      end
    end

    context 'when the HTTP response is a 200' do
      let(:service) {
        Docker::Service.create({ 'TaskTemplate' => { 'ContainerSpec' => { 'Image' => 'debian:wheezy' } } })
      }
      let(:task) { subject.all.first }
      after { service.remove }

      it 'materializes the Task into a Docker::Task' do
        expect(subject.get(task.id)).to be_a Docker::Task
      end
    end
  end
end
