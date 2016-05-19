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
    shrine_class = Class.new(Shrine)
    shrine_class.storages[:sql] = @sql
    @uploader = shrine_class.new(:sql)
  end

  after do
    @sql.clear!
  end

  it "passes the linter" do
    Shrine::Storage::Linter.new(@sql).call
  end

  describe "#upload" do
    it "copies an UploadedFile from SQL storage" do
      uploaded_file = @uploader.upload(fakeio, location: "foo.jpg")
      @sql.upload(uploaded_file, id = "foo")
      record = @sql.dataset.where(id: id).first!

      refute_empty record[:content]
      refute_empty record[:metadata]
    end
  end

  describe "#download" do
    it "preserves the extension" do
      @sql.upload(fakeio, id = "foo.jpg")
      tempfile = @sql.download(id)

      assert_equal ".jpg", File.extname(tempfile.path)
    end
  end
end
