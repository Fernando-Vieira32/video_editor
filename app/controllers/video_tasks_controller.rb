class VideoTasksController < ApplicationController
  def index
    @operations = Video::Registry.all
    @video_tasks = VideoTask.order(created_at: :desc).limit(50)
  end

  def show
    @video_task = VideoTask.find(params[:id])
  end

  def status
    render partial: "video_tasks/status",
      locals: { video_task: VideoTask.find(params[:id]) }
  end

  def new
    @operation = Video::Registry.find!(params[:operation])
    @video_task = VideoTask.new(operation: @operation.key)
  end

  def create
    @video_task = VideoTask.new(video_task_params)
    return redirect_to(@video_task) if @video_task.save

    @operation = @video_task.operation_class
    render :new, status: :unprocessable_entity
  end

  def clear
    VideoTask.find_each { |task| task.purge_files && task.destroy }
    ActiveStorage::Blob.unattached.find_each(&:purge)
    redirect_to root_path, notice: "Histórico limpo."
  end

  private

  def video_task_params
    params.require(:video_task).permit(:operation, :source, params: {})
  end
end
