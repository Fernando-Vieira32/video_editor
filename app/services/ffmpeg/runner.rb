require "open3"

module Ffmpeg
  # Runs an FFmpeg command and captures its combined output.
  class Runner
    Result = Data.define(:success, :output) do
      def success? = success
    end

    def self.call(args) = new(args).call

    def initialize(args) = @args = args

    def call
      output, status = Open3.capture2e("ffmpeg", "-y", *@args)
      Result.new(success: status.success?, output:)
    end
  end
end
