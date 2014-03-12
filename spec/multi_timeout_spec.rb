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

    def capture_stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = STDOUT
    end

    it "times out first signal first" do
      MultiTimeout::CLI.should_receive(:puts)
      status = nil
      time {
        status = call(["-2", "1", "-9", "2", "sleep", "2"])
      }.should be_within(0.1).of(1)
      status.should == 1
    end

    it "can use string exit status" do
      status = nil
      MultiTimeout::CLI.should_receive(:puts).with("Killing 'sleep 2' with signal INT after 1 seconds")
      time {
        status = call(["-INT", "1", "sleep", "2"])
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
        status = call(["-2", "1", "-9", "2", "sh", "-c", "exit 123"])
      }.should be_within(0.1).of(0)
      status.should == 123
    end

    it "kills hard if soft-kill fails" do
      begin
        command = "ruby -e Signal.trap\\(2\\)\\{\\..."
        file = "xxx"
        capture_stdout {
          call(["-2", "1", "-9", "2", "ruby", "-e", "Signal.trap(2){ File.open('#{file}', 'w'){|f|f.write('2')} }; sleep 4"]).should == 1
        }.should == "Killing '#{command}' with signal 2 after 1 seconds\nKilling '#{command}' with signal 9 after 2 seconds\n"
        File.read(file).should == "2"
      ensure
        File.unlink(file) if File.exist?(file)
      end
    end

    it "kills nested processes" do
      begin
        file = 'xxx'
        capture_stdout {
          call(["-2", "1", "env", "XXX=1", "sh", "-c", "(sleep 1.5 && touch #{file})"])
        }
        sleep 1
        File.exist?(file).should == false
      ensure
        File.unlink(file) if File.exist?(file)
      end
    end
  end

  describe "#multi" do
    def call(*argv)
      MultiTimeout::CLI.send(:truncate, *argv)
    end

    it "does not truncate correct size" do
      call("abcdef", 6).should == "abcdef"
    end

    it "does not truncate short size" do
      call("abc", 6).should == "abc"
    end

    it "does not truncate long size" do
      call("abcdefgh", 6).should == "abc..."
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

    it "fails on invalid" do
      expect { call("m123") }.to raise_error
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

    it "finds string signals" do
      call(["10m", "-v", "-HUP", "1m", "--help"]).should == [[["HUP", 60]], ["10m", "-v", "--help"]]
    end

    it "finds string number signals" do
      call(["10m", "-v", "-USR2", "1m", "--help"]).should == [[["USR2", 60]], ["10m", "-v", "--help"]]
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

    it "fails on invalid option" do
      expect { call(["-9", "1", "-f", "1", "sleep", "1"]) }.to raise_error
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

  describe "#consume_command" do
    def call(*argv)
      MultiTimeout::CLI.send(:consume_command, *argv)
    end

    it "leaves only command" do
      call(["xxx", "-v"]).should == ["xxx -v", []]
    end

    it "splits command and options" do
      call(["-x", "-y", "xxx", "-v"]).should == ["xxx -v", ["-x", "-y"]]
    end
  end

  describe "CLI" do
    def timeout(command, options={})
      sh("#{Bundler.root}/bin/multi-timeout #{command}", options)
    end

    def sh(command, options={})
      result = Bundler.with_clean_env { `#{command} #{"2>&1" unless options[:keep_output]}` }
      raise "#{options[:fail] ? "SUCCESS" : "FAIL"} #{command}\n#{result}" if $?.success? == !!options[:fail]
      result
    end


    it "can print version" do
      timeout("-v").should == "#{MultiTimeout::VERSION}\n"
    end

    it "can print help" do
      timeout("-h").should include "Usage"
    end

    it "execute successfully" do
      timeout("-2 1 sleep 0").should == ""
    end

    it "fails" do
      timeout("-2 1 sleep 2", :fail => true).should == "Killing 'sleep 2' with signal 2 after 1 seconds\n"
    end
  end
end
