require 'spec_helper'

SingleCov.covered! uncovered: 1

describe Docker::Service do
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
        subject.create({ 'TaskTemplate' => { 'ContainerSpec' => { 'Image' => 'debian:wheezy' } } })
      }
      before { service }
      after { service.remove }

      it 'materializes each Service into a Docker::Service' do
        expect(subject.all(:all => true)).to be_all { |service|
          service.is_a?(Docker::Service)
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
        subject.create({ 'TaskTemplate' => { 'ContainerSpec' => { 'Image' => 'debian:wheezy' } } })
      }
      after { service.remove }

      it 'materializes the Service into a Docker::Service' do
        expect(subject.get(service.id)).to be_a Docker::Service
      end
    end
  end

  describe '.create' do
    subject { described_class }

    context 'when the Service does not yet exist' do
      context 'when the HTTP request does not return a 200' do
        before do
          Docker.options = { :mock => true }
          Excon.stub({ :method => :post }, { :status => 400 })
        end
        after do
          Excon.stubs.shift
          Docker.options = {}
        end

        it 'raises an error' do
          expect { subject.create }.to raise_error(Docker::Error::ClientError)
        end
      end

      context 'when the HTTP request returns a 200' do
        let(:options) do
          {
            "Name" => "example_service",
            "TaskTemplate" => {
              "ContainerSpec" => {
                "Image" => "debian:wheezy"
              }
            }
          }
        end
        let(:service) { subject.create(options) }
        after { service.remove }

        it 'sets the id' do
          expect(service).to be_a Docker::Service
          expect(service.id).to_not be_nil
          expect(service.connection).to_not be_nil
        end
      end
    end
  end

  describe "#update" do
    subject { described_class }

    let(:service) {
      subject.create({ 'TaskTemplate' => { 'ContainerSpec' => { 'Image' => 'debian:wheezy' } } })
    }
    after { service.remove }

    it "updates the service" do
      expect(subject.get(service.id).info.fetch("Spec").fetch("Mode").fetch("Replicated").fetch("Replicas")).to eq 1
      service.update({}, { 'TaskTemplate' => { 'ContainerSpec' => { 'Image' => 'debian:wheezy' } }, "Mode" => { "Replicated" => { "Replicas" => 3 } } })
      expect(subject.get(service.id).info.fetch("Spec").fetch("Mode").fetch("Replicated").fetch("Replicas")).to eq 3
    end
  end

  describe '#delete' do
    subject {
      described_class.create({
        "TaskTemplate" => {
          "ContainerSpec" => {
            "Image" => "debian:wheezy"
          }
        }
      })
    }

    it 'deletes the service' do
      subject.delete(:force => true)
      expect(described_class.all.map(&:id)).to be_none { |id|
        id.start_with?(subject.id)
      }
    end
  end

  describe '#logs' do
    subject {
      described_class.create({
        "TaskTemplate" => {
          "ContainerSpec" => {
            "Image" => "debian:wheezy"
          }
        }
      })
    }
    after(:each) { subject.remove }

    context "when not selecting any stream" do
      let(:non_destination) { subject.logs }
      it 'raises a client error' do
        pending("this feature is only supported with experimental daemon")
        expect { non_destination }.to raise_error(Docker::Error::ClientError)
      end
    end

    context "when selecting stdout" do
      let(:stdout) { subject.logs(stdout: 1) }
      it 'returns blank logs' do
        pending("this feature is only supported with experimental daemon")
        expect(stdout).to be_a String
        expect(stdout).to eq ""
      end
    end
  end

  describe '#streaming_logs' do
    subject {
      described_class.create({
        "TaskTemplate" => {
          "ContainerSpec" => {
            "Image" => "debian:wheezy"
          }
        }
      })
    }

    after(:each) { subject.remove }

    context 'when not selecting any stream' do
      let(:non_destination) { subject.streaming_logs }
      it 'raises a client error' do
        pending("this feature is only supported with experimental daemon")
        expect { non_destination }.to raise_error(Docker::Error::ClientError)
      end
    end

    context 'when selecting stdout' do
      let(:stdout) { subject.streaming_logs(stdout: 1) }
      it 'returns blank logs' do
        pending("this feature is only supported with experimental daemon")
        expect(stdout).to be_a String
        expect(stdout).to match("")
      end
    end

    context 'when using a tty' do
      let(:output) { subject.streaming_logs(stdout: 1, tty: 1) }
      it 'returns blank logs' do
        pending("this feature is only supported with experimental daemon")
        expect(output).to be_a(String)
        expect(output).to match("")
      end
    end
  end
end
