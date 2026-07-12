module Video
  # Describes a single input of an operation, used to auto-render its form.
  Field = Data.define(:name, :type, :label, :required, :placeholder, :hint, :default) do
    def initialize(name:, type: :string, label: nil, required: false, placeholder: nil, hint: nil, default: nil)
      super(name:, type:, label: label || name.to_s.humanize, required:, placeholder:, hint:, default:)
    end

    def param_key = name.to_s
  end
end
