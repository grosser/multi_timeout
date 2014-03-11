require "spec_helper"

describe MultiTimeout do
  def time(&block)
    Benchmark.realtime(&block)
  end

  it "has a VERSION" do
    MultiTimeout::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe "#run" do
    def call(*argv)
      MultiTimeout::CLI.run(*argv)
    end

    it "times out first signal first" do
      MultiTimeout::CLI.should_receive(:puts)
      status = nil
      time {
        status = call(["-2", "1", "-9", "2", "sleep", "2"])
      }.should be_within(0.1).of(1)
      status.should == 1
    end

    it "exists with sub process ok exit status" do
      status = nil
      time {
        status = call(["-2", "1", "-9", "2", "sleep", "0"])
      }.should be_within(0.1).of(0)
      status.should == 0
    end

    it "exists with sub process bad exit status" do
      status = nil
      time {
        status = call(["-2", "1", "-9", "2", "exit", "123"])
      }.should be_within(0.1).of(0)
      status.should == 123
    end
  end

  describe "#multi" do
    def call(*argv)
      MultiTimeout::CLI.send(:multi, *argv)
    end

    it "finds seconds" do
      call("51s").should == 1
    end

    it "finds nothing" do
      call("51").should == 1
    end

    it "finds minutes" do
      call("10m").should == 60
    end

    it "finds hours" do
      call("10h").should == 3600
    end

    it "fails on unknown" do
      expect { call("10x") }.to raise_error
    end
  end

  describe "#consume_signals" do
    def call(*argv)
      MultiTimeout::CLI.send(:consume_signals, *argv)
    end

    it "finds nothing" do
      call([]).should == [[], []]
    end

    it "does not find unrelated" do
      call(["10m", "-v", "--help"]).should == [[], ["10m", "-v", "--help"]]
    end

    it "finds 1 signal" do
      call(["10m", "-v", "-9", "1m", "--help"]).should == [[[9, 60]], ["10m", "-v", "--help"]]
    end

    it "finds multiple signals" do
      call(["10m", "-v", "-9", "1m", "-2", "22s", "--help"]).should == [[[9, 60], [2, 22]], ["10m", "-v", "--help"]]
    end
  end

  describe "#parse_options" do
    def call(*argv)
      MultiTimeout::CLI.send(:parse_options, *argv)
    end

    it "parses normal" do
      call(["-9", "10m", "sleep", "100"]).should == {:timeouts => [[9, 600]], :command => "sleep 100"}
    end

    it "fails on missing timeouts" do
      expect { call(["sleep", "100"]) }.to raise_error
    end
  end

  describe "#dead?" do
    def call(*argv)
      MultiTimeout::CLI.send(:dead?, *argv)
    end

    it "is dead when dead" do
      call(1212312).should == true
    end

    it "is not dead when alive" do
      call(Process.pid).should == false
    end
  end
end
