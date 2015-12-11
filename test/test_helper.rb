require "minitest/autorun"
require "minitest/pride"

require "shrine/storage/sql"

require "forwardable"
require "stringio"

class FakeIO
  def initialize(content)
    @io = StringIO.new(content)
  end

  extend Forwardable
  delegate [:read, :size, :close, :eof?, :rewind] => :@io
end

class Minitest::Test
  def fakeio(content = "file")
    FakeIO.new(content)
  end
end
