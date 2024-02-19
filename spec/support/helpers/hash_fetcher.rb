class HashFetcher
  attr_accessor :data

  def initialize(**opts)
    @data = opts
  end

  def fetch
    data
  end
end
