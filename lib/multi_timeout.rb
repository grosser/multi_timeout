require "multi_timeout/version"
require "shellwords"
require "optparse"

module MultiTimeout
  module CLI
    TICK = 1
    VALID_SIGNAL = /^(-(\d+|[A-Z\d]+))$/

    class << self
      def run(argv)
        options = parse_options(argv)
        command = options[:command]

        pid = Process.spawn command, :pgroup => true
        gid = Process.getpgid(pid)
        Thread.new do
          now = 0
          loop do
            break if dead?(pid)

            options[:timeouts].each do |signal, t|
              if now >= t
                options[:timeouts].delete([signal, t])
                puts "Killing '#{truncate(command, 30)}' with signal #{signal} after #{now} seconds"
                Process.kill(signal, -gid)
              end
            end
            now += TICK
            sleep TICK
          end
        end

        Process.wait2(pid).last.exitstatus || 1
      end

      private

      def truncate(string, count)
        if string.size > count
          string.slice(0, count-3) + "..."
        else
          string
        end
      end

      def dead?(pid)
        Process.getpgid(pid)
        false
      rescue Errno::ESRCH
        true
      end

      def parse_options(argv)
        options = {:timeouts => []}
        options[:timeouts], argv = consume_signals(argv)
        options[:command], argv = consume_command(argv)

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

        options
      end

      def consume_command(argv)
        argv = argv.dup
        options = []
        while argv.first =~ /^-/
          options << argv.shift
        end
        return Shellwords.shelljoin(argv), options
      end

      def consume_signals(argv)
        timeouts = []
        signal = nil
        argv = argv.map do |item|
          if !signal && item =~ VALID_SIGNAL
            signal = $1
            next
          elsif signal
            signal = signal.sub("-", "")
            signal = signal.to_i if signal =~ /^\d+$/
            timeouts << [signal, human_value_to_seconds(item)]
            signal = nil
            next
          else
            item
          end
        end.compact

        return timeouts, argv
      end

      def human_value_to_seconds(t)
        unit =
          case t
          when /^\d+s$/ then 1
          when /^\d+m$/ then 60
          when /^\d+h$/ then 60 * 60
          when /^\d+$/  then 1
          else raise "Unknown format for time #{t}"
          end
        t.to_i * unit
      end
    end
  end
end
