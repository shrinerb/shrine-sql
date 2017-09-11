require "test_helper"
require "shrine/storage/linter"
require "sequel"
require "time"

DB = Sequel.sqlite("db.sqlite3")
DB.create_table! :files do
  primary_key :id
  File :content
  String :metadata, text: true
  Time :created_at
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
    it "sets #created_at" do
      now = Time.now
      @sql.upload(fakeio, id = "foo")
      record = @sql.dataset.where(id: id).first!

      assert_instance_of Time, record[:created_at]
      assert_operator record[:created_at].iso8601, :>=, now.iso8601
    end

    it "copies an UploadedFile from SQL storage" do
      uploaded_file = @uploader.upload(fakeio("file"))
      now = Time.now
      @sql.upload(uploaded_file, id = "foo")

      record = @sql.dataset.where(id: id).first!

      assert_equal "file",                         record[:content]
      assert_equal uploaded_file.metadata.to_json, record[:metadata]
      assert_instance_of Time,                     record[:created_at]
      assert_operator record[:created_at].iso8601, :>=, now.iso8601
    end
  end

  describe "#clear!" do
    it "accepts a block for specifying the dataset" do
      now = Time.now
      @sql.dataset.multi_insert([{ created_at: now }, { created_at: now - 10 }])
      @sql.clear! { |dataset| dataset.where{created_at < now - 5} }

      records = @sql.dataset.all

      assert_equal 1,   records.count
      assert_equal now, records.first[:created_at]
    end
  end
end
