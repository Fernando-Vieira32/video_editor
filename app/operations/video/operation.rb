module Video
  # Base class for every video feature. A subclass describes itself (label,
  # icon, form fields) and knows how to build its FFmpeg command. The UI and
  # the processor are driven entirely by this interface, so adding a feature
  # means adding a subclass and registering it in Video::Registry.
  class Operation
    def self.key = name.demodulize.underscore
    def self.label = raise(NotImplementedError, "#{self} must define .label")
    def self.description = ""
    def self.icon = "🎬"
    def self.fields = []

    # When true, the new form renders the visual timeline trimmer.
    def self.timeline? = false

    # How the timeline preview treats the marked range: "keep" or "remove".
    def self.timeline_mode = "keep"

    def initialize(task) = @task = task

    # Returns the FFmpeg arguments (without the leading 'ffmpeg -y').
    def command(_input_path, _output_path) = raise(NotImplementedError, "#{self.class} must define #command")

    # Extension of the produced file; defaults to keeping the source's.
    def output_extension(source_filename) = File.extname(source_filename).presence || ".mp4"

    # Returns an array of human-readable error messages for the given params.
    def validate = []

    private

    attr_reader :task

    def params = task.params || {}
  end
end
