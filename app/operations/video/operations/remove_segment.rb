require "tmpdir"

module Video
  module Operations
    # Removes the marked segment (start..end) and joins the surrounding parts.
    # Uses stream copy (no re-encode): cuts the head (0..start) and tail
    # (end..EOF) then concatenates them. Fast and light; cut points snap to the
    # nearest keyframe.
    class RemoveSegment < Operation
      def self.label = "Remover trecho"
      def self.description = "Remove o pedaço marcado e junta o antes com o depois."
      def self.icon = "🗑️"
      def self.timeline? = true
      def self.timeline_mode = "remove"
      def self.preview_hint = "A prévia reproduz o vídeo final, pulando o trecho vermelho."

      def self.fields
        [
          Field.new(name: :start, label: "Início do trecho a remover", default: "00:00:00",
            required: true, placeholder: "00:01:30", hint: "Onde o corte começa"),
          Field.new(name: :end, label: "Fim do trecho a remover", required: true,
            placeholder: "00:03:45", hint: "Onde o corte termina")
        ]
      end

      def call(input, output)
        @input = input
        Dir.mktmpdir { |dir| run_pipeline(output, dir) }
      end

      def validate
        [].tap do |errors|
          errors << "Tempo de início inválido" unless valid_time?(raw_start)
          errors << "Tempo de fim inválido" unless valid_time?(raw_end)
        end
      end

      private

      def run_pipeline(output, dir)
        head = File.join(dir, "head#{container_ext}")
        tail = File.join(dir, "tail#{container_ext}")
        result = Ffmpeg::Runner.call([ "-i", @input, "-to", raw_start, "-c", "copy", head ])
        result.success? ? join(head, tail, output, dir) : result
      end

      def join(head, tail, output, dir)
        result = Ffmpeg::Runner.call([ "-ss", raw_end, "-i", @input, "-c", "copy", tail ])
        result.success? ? Ffmpeg::Runner.call(concat_args(head, tail, output, dir)) : result
      end

      def concat_args(head, tail, output, dir)
        list = File.join(dir, "list.txt")
        File.write(list, "file '#{head}'\nfile '#{tail}'\n")
        [ "-f", "concat", "-safe", "0", "-i", list, "-c", "copy", output ]
      end

      def container_ext = File.extname(task.source.filename.to_s).presence || ".mp4"
      def raw_start = params["start"].presence || "00:00:00"
      def raw_end = params["end"].to_s

      def valid_time?(time)
        time.match?(/\A\d{1,2}:\d{2}:\d{2}(\.\d{1,3})?\z/) ||
          time.match?(/\A\d{1,2}:\d{2}(\.\d{1,3})?\z/)
      end
    end
  end
end
