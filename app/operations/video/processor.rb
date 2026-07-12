require "tempfile"

module Video
  # Orchestrates one task: downloads the source, runs the operation's FFmpeg
  # command against a temp file and attaches the result. Status transitions
  # broadcast to the task's Turbo stream via the model callbacks.
  class Processor
    def self.call(task) = new(task).call

    def initialize(task) = @task = task

    def call
      task.processing!
      task.source.open { |input| process(input.path) }
    rescue StandardError => e
      task.update!(status: :failed, error_message: e.message.to_s.last(2000))
    end

    private

    attr_reader :task

    def process(input_path)
      output = Tempfile.new([ "output", extension ])
      finish(Ffmpeg::Runner.call(operation.command(input_path, output.path)), output)
    ensure
      output&.close!
    end

    def finish(result, output)
      return fail_task(result.output) unless result.success?

      task.result.attach(io: File.open(output.path), filename: output_filename)
      task.completed!
    end

    def fail_task(output) = task.update!(status: :failed, error_message: output.to_s.last(2000))

    def operation = @operation ||= task.operation_class.new(task)
    def source_name = task.source.filename.to_s
    def extension = operation.output_extension(source_name)
    def output_filename = "#{File.basename(source_name, '.*')}_#{task.operation}#{extension}"
  end
end
