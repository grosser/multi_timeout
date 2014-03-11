require "multi_timeout/version"
require "shellwords"
require "optparse"

module MultiTimeout
  module CLI
    TICK = 1

    class << self
      def run(argv)
        options = parse_options(argv)
        command = options[:command]

        pid = Process.spawn(command)
        Thread.new do
          now = 0
          loop do
            break if dead?(pid)

            options[:timeouts].each do |signal, t|
              if now >= t
                puts "Killing #{command} with signal #{signal} after #{now} seconds"
                Process.kill(signal, pid)
              end
            end
            now += TICK
            sleep TICK
          end
        end

        Process.wait2.last.exitstatus || 1
      end

      private

      def dead?(pid)
        Process.getpgid(pid)
        false
      rescue Errno::ESRCH
        true
      end

      def parse_options(argv)
        options = {:timeouts => []}
        options[:timeouts], argv = consume_signals(argv)


        OptionParser.new do |opts|
          opts.banner = <<-BANNER.gsub(/^ {10}/, "")
            Use multiple timeouts to soft and then hard kill a command

            Usage:
                multi-timeout -9 5s -2 4s sleep 20

            Options:
          BANNER
          opts.on("-SIGNAL TIME", Integer, "Kill with this SIGNAL after TIME") { raise } # this is never used, just placeholder for docs
          opts.on("-h", "--help", "Show this.") { puts opts; exit }
          opts.on("-v", "--version", "Show Version"){ puts MultiTimeout::VERSION; exit}
        end.parse!(argv)

        raise "No timeouts given" if options[:timeouts].empty?
        options[:command] = Shellwords.shelljoin(argv)

        options
      end

      def consume_signals(argv)
        timeouts = []
        signal = nil
        argv = argv.map do |item|
          if !signal && item =~ /^(-\d+)$/
            signal = $1
            next
          elsif signal && item =~ /^(\d+[smh]?)$/
            time = $1
            timeouts << [signal.sub("-", "").to_i, time.to_i * multi(time)]
            signal = nil
            next
          else
            item
          end
        end.compact

        return timeouts, argv
      end

      def multi(t)
        case t
        when /s/ then 1
        when /m/ then 60
        when /h/ then 60 * 60
        when /^\d+$/ then 1
        else
          raise "Unknown format for time #{t}"
        end
      end
    end
  end
end
