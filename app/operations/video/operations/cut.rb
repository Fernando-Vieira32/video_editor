module Video
  module Operations
    # Cuts a segment between two timestamps without re-encoding (fast).
    class Cut < Operation
      def self.label = "Cortar vídeo"
      def self.description = "Corta um trecho entre dois tempos, sem recodificar."
      def self.icon = "✂️"
      def self.timeline? = true
      def self.preview_hint = "A prévia reproduz apenas o trecho selecionado (o que será mantido)."

      def self.fields
        [
          Field.new(name: :start, label: "Início", default: "00:00:00", required: true,
            placeholder: "00:01:30", hint: "HH:MM:SS ou MM:SS (milissegundos opcionais: 01:30.500)"),
          Field.new(name: :end, label: "Fim", required: true,
            placeholder: "00:03:45", hint: "HH:MM:SS ou MM:SS"),
          Field.new(name: :no_audio, type: :boolean, label: "Remover áudio")
        ]
      end

      def command(input, output)
        [ "-i", input, "-ss", start_time, "-to", end_time, *codec_args,
         "-avoid_negative_ts", "make_zero", output ]
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
      def start_time = normalize(raw_start)
      def end_time = normalize(raw_end)
      def no_audio? = ActiveModel::Type::Boolean.new.cast(params["no_audio"])
      def codec_args = no_audio? ? [ "-c:v", "copy", "-an" ] : [ "-c", "copy" ]

      def valid_time?(time)
        time.match?(/\A\d{1,2}:\d{2}:\d{2}(\.\d{1,3})?\z/) ||
          time.match?(/\A\d{1,2}:\d{2}(\.\d{1,3})?\z/)
      end

      def normalize(time) = time.count(":") == 1 ? "00:#{time}" : time
    end
  end
end
