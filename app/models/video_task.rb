class VideoTask < ApplicationRecord
  has_one_attached :source
  has_one_attached :result

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :operation, presence: true, inclusion: { in: ->(_) { Video::Registry.keys } }
  validates :source, presence: true
  validate :operation_params_valid

  after_create_commit :enqueue

  def operation_class = Video::Registry.find(operation)
  def label = operation_class&.label || operation
  def finished? = completed? || failed?

  def purge_files
    [ source, result ].each { |file| file.purge if file.attached? }
  end

  private

  def operation_instance = operation_class&.new(self)

  def operation_params_valid
    operation_instance&.validate&.each { |message| errors.add(:base, message) }
  end

  def enqueue = VideoProcessingJob.perform_later(id)
end
