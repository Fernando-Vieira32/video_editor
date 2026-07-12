require "open3"

module Ffmpeg
  # Lightweight ffprobe queries about a media file.
  module Probe
    module_function

    def has_audio?(path)
      out, status = Open3.capture2("ffprobe", "-v", "error", "-select_streams", "a",
        "-show_entries", "stream=index", "-of", "csv=p=0", path)
      status.success? && out.strip.present?
    end
  end
end
