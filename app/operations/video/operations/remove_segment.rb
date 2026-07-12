module Video
  module Operations
    # Removes the marked segment (start..end) and joins the surrounding parts.
    # Re-encodes because the join happens at non-keyframe boundaries.
    class RemoveSegment < Operation
      def self.label = "Remover trecho"
      def self.description = "Remove o pedaço marcado e junta o antes com o depois."
      def self.icon = "🗑️"
      def self.timeline? = true
      def self.timeline_mode = "remove"

      def self.fields
        [
          Field.new(name: :start, label: "Início do trecho a remover", default: "00:00:00",
            required: true, placeholder: "00:01:30", hint: "Onde o corte começa"),
          Field.new(name: :end, label: "Fim do trecho a remover", required: true,
            placeholder: "00:03:45", hint: "Onde o corte termina")
        ]
      end

      def command(input, output)
        [ "-i", input, "-filter_complex", filtergraph(input), *maps(input), output ]
      end

      def validate
        [].tap do |errors|
          errors << "Tempo de início inválido" unless valid_time?(raw_start)
          errors << "Tempo de fim inválido" unless valid_time?(raw_end)
        end
      end

      private

      def raw_start = params["start"].presence || "00:00:00"
      def raw_end = params["end"].to_s
      def audio?(input) = Ffmpeg::Probe.has_audio?(input)

      def filtergraph(input)
        audio?(input) ? "#{video_graph}#{audio_graph}#{concat(1)}" : "#{video_graph}#{concat(0)}"
      end

      def video_graph
        "[0:v]trim=end=#{start_secs},setpts=PTS-STARTPTS[v0];" \
          "[0:v]trim=start=#{end_secs},setpts=PTS-STARTPTS[v1];"
      end

      def audio_graph
        "[0:a]atrim=end=#{start_secs},asetpts=PTS-STARTPTS[a0];" \
          "[0:a]atrim=start=#{end_secs},asetpts=PTS-STARTPTS[a1];"
      end

      def concat(audio)
        parts = audio.positive? ? "[v0][a0][v1][a1]" : "[v0][v1]"
        "#{parts}concat=n=2:v=1:a=#{audio}[outv]#{'[outa]' if audio.positive?}"
      end

      def maps(input)
        audio?(input) ? [ "-map", "[outv]", "-map", "[outa]" ] : [ "-map", "[outv]" ]
      end

      def start_secs = to_seconds(raw_start)
      def end_secs = to_seconds(raw_end)

      def to_seconds(time)
        parts = time.split(":").map(&:to_f)
        parts.reduce(0.0) { |acc, part| acc * 60 + part }
      end

      def valid_time?(time)
        time.match?(/\A\d{1,2}:\d{2}:\d{2}(\.\d{1,3})?\z/) ||
          time.match?(/\A\d{1,2}:\d{2}(\.\d{1,3})?\z/)
      end
    end
  end
end
