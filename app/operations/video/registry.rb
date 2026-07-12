module Video
  # Single source of truth for the available features. To add a new feature,
  # create its Video::Operations::* class and list it here.
  module Registry
    module_function

    def all = [ Operations::RemoveSegment, Operations::Cut ]

    def keys = all.map(&:key)

    def find(key) = all.find { |op| op.key == key.to_s }

    def find!(key) = find(key) || raise(ActiveRecord::RecordNotFound, "Unknown operation: #{key}")
  end
end
