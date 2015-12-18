require "test_helper"
require "shrine/storage/linter"
require "sequel"

DB = Sequel.connect(adapter: "sqlite", database: "db.sqlite3")

DB.create_table! :files do
  primary_key :id
  column :content, :text
  column :metadata, :text
end

describe Shrine::Storage::Sql do
  def sql(options = {})
    options[:database] ||= DB
    options[:table]    ||= :files

    Shrine::Storage::Sql.new(options)
  end

  before do
    @sql = sql
  end

  after do
    @sql.clear!(:confirm)
  end

  it "passes the linter" do
    Shrine::Storage::Linter.new(@sql, action: :warn).call
  end

  describe "#download" do
    it "preserves the extension" do
      @sql.upload(fakeio, id = "foo", {"filename" => "foo.jpg"})
      tempfile = @sql.download(id)

      assert_equal ".jpg", File.extname(tempfile.path)
    end
  end
end
