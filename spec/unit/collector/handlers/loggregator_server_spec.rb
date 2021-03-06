require 'spec_helper'

describe Collector::Handler::Router do

  class FakeHistorian
    attr_reader :sent_data

    def initialize
      @sent_data = []
    end

    def send_data(data)
      @sent_data << data
    end

    def has_sent_data?(key, value, tags={})
      @sent_data.any? do |data|
        data[:key] == key && data[:value] == value &&
            data[:tags] == data[:tags].merge(tags)
      end
    end
  end

  let(:historian) { FakeHistorian.new }
  let(:timestamp) { 123456789 }
  let(:handler) { Collector::Handler::LoggregatorServer.new(historian, "job") }
  let(:context) { Collector::HandlerContext.new(1, timestamp, varz) }

  describe "process" do
    let(:varz) do
      {
          "name" => "LoggregatorServer",
          "numCPUS" => 1,
          "numGoRoutines" => 1,
          "tags" => {
              "ip" => "10.10.10.10"
          },
          "memoryStats" => {
            "numBytesAllocatedHeap" => 1024,
            "numBytesAllocatedStack" => 4096,
            "numBytesAllocated" => 2048,
            "numMallocs" => 3,
            "numFrees" => 10,
            "lastGCPauseTimeNS" => 1000
          },
          "contexts" => [
              {"name" => "agentListener",
               "metrics" => [
                   {"name" => "currentBufferCount", "value" => 12},
                   {"name" => "receivedMessageCount", "value" => 45},
                   {"name" => "receivedByteCount", "value" => 6}]},
              {"name" => "sinkServer",
               "metrics" => [
                   {"name" => "numberOfSinks", "value" => 9, "tags" => {"tag1" => "tagValue1", "tag2" => "tagValue2"}}
               ]
              }
          ]
      }
    end


    it "sends the metrics" do
      handler.process(context)
      historian.should have_sent_data("LoggregatorServer.numCpus", 1)
      historian.should have_sent_data("LoggregatorServer.numGoRoutines", 1)
      historian.should have_sent_data("LoggregatorServer.memoryStats.numBytesAllocatedHeap", 1024)
      historian.should have_sent_data("LoggregatorServer.memoryStats.numBytesAllocatedStack", 4096)
      historian.should have_sent_data("LoggregatorServer.memoryStats.numBytesAllocated", 2048)
      historian.should have_sent_data("LoggregatorServer.memoryStats.numMallocs", 3)
      historian.should have_sent_data("LoggregatorServer.memoryStats.numFrees", 10)
      historian.should have_sent_data("LoggregatorServer.memoryStats.lastGCPauseTimeNS", 1000)
      historian.should have_sent_data("LoggregatorServer.agentListener.currentBufferCount", 12)
      historian.should have_sent_data("LoggregatorServer.agentListener.receivedMessageCount", 45)
      historian.should have_sent_data("LoggregatorServer.agentListener.receivedByteCount", 6)
      historian.should have_sent_data("LoggregatorServer.sinkServer.numberOfSinks", 9, {"ip"=>"10.10.10.10", "tag1" => "tagValue1", "tag2" => "tagValue2"})
    end
  end
end
