class VideoProcessingJob < ApplicationJob
  queue_as :default

  def perform(task_id)
    Video::Processor.call(VideoTask.find(task_id))
  end
end
