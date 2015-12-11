require "test_helper"
require "shrine/storage/linter"
require "sequel"

DB = Sequel.connect(adapter: "sqlite", database: "db.sqlite3")

DB.create_table! :files do
  primary_key :id
  column :content, :text
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
end
