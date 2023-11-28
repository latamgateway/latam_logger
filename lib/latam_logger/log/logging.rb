# frozen_string_literal: true

require "logger"
require "json"

module LatamLogger
  module Log
    class Logging
      attr_reader :logger

      def initialize
        @logger = Logger.new(ENV['LATAM_LOGGER_PATH_FILE'] || STDOUT)
        @logger.formatter = method(:format_log)
        Datadog::Tracing.trace('operations') {
          @correlation = Datadog::Tracing.correlation
        }
      end

      %w[debug info warn error].each do |level|
        define_method(level) do |log|
          Datadog::Tracing.trace('operations') {
            @logger.send(level, log)
          }
        end
      end

      def format_log(severity, datetime, progname, msg)
        if msg.is_a?(Hash)
          msg[:level] = severity
          msg[:date] = datetime
          msg[:"dd.trace_id"] = @correlation.trace_id
        else
          msg = {
            level: severity,
            date: datetime,
            message: msg
          }
        end

        msg.to_json + "\n"
      end

    end
  end
end
