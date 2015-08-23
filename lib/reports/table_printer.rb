require 'active_support/core_ext/hash/keys'

require_relative './number_humanizer'

module Reports

  # TablePrinter prints a hash of keys and values in a nicely formatted table.
  # The rows are sorted by value from larges to smallest. A blank line and then
  # a total line are printed beneath the table.
  class TablePrinter
    include NumberHumanizer

    # io - an object that responds to #puts.
    def initialize(io)
      @io = io
    end

    # Print a nice table to @io using data_hash and options.
    # data_hash - a Hash containing String keys and Numeric values, which will
    #             be used as the value and label for a row in the table.
    # options - A Hash optionally containing:
    #   title - A String to display above the table. Defaults to no title.
    #   total - If an additional row containing totals should be appended to
    #           the end of the table. Defaults to false.
    #   humanize - If Numeric values should be printed in a human-friendly
    #              format. Defaults to false.
    def print(data_hash, options={})
      options.symbolize_keys!

      total = data_hash.values.inject(0) {|sum, v| sum + v}.to_f
      sorted = data_hash.sort_by {|k,v| -v}

      if options[:title]
        @io.puts format("* * * %s * * *", options[:title])
      end

      sorted.each do |key, value|
        @io.puts format_line(value, value/total, key, options)
      end

      if options[:total]
        @io.puts
        @io.puts format_line(total, 1.0, "total", options)
      end
    end

    private

    def format_line(value, percentage, label, options={})
      if options[:humanize]
        humanized = humanize_number(value)
        humanized << ' ' if humanized =~ /\sB$/

        format("%7s  %#5.1f%%  %s", humanized, percentage * 100, label)
      else
        format("%3d  %#5.1f%%  %s", value, percentage * 100, label)
      end
    end
  end
end
