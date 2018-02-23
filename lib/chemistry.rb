require "chemistry/engine"

module Chemistry
  # Your code goes here...

  class << self
    mattr_accessor :layout
                   :something

    self.layout = "application"
  end

  def self.configure
    yield self
  end

end
