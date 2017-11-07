require "shrine"
require "sequel"

require "stringio"
require "json"

class Shrine
  module Storage
    class Sql
      attr_reader :database, :table

      def initialize(database:, table:)
        @database = database
        @table    = table
      end

      def upload(io, id, **options)
        generated_id = store(io, id, **options)
        id.replace(generated_id.to_s + File.extname(id))
      end

      def open(id)
        StringIO.new(content(id))
      end

      def exists?(id)
        !find(id).get(Sequel::SQL::AliasedExpression.new(1, :one)).nil?
      end

      def delete(id)
        find(id).delete
      end

      def url(id, **options)
      end

      def clear!
        dataset = self.dataset
        dataset = yield dataset if block_given?
        dataset.delete
      end

      def dataset
        database[table]
      end

      protected

      def find(id_or_ids)
        ids = Array(id_or_ids).map { |s| File.basename(s, ".*") }
        dataset.where(id: ids)
      end

      private

      def store(io, id, **options)
        if copyable?(io, id)
          copy(io, id, **options)
        else
          insert(io, id, **options)
        end
      end

      def insert(io, id, shrine_metadata: {}, **options)
        record = {}
        record[:content]    = Sequel::SQL::Blob.new(io.read)
        record[:metadata]   = shrine_metadata.to_json
        record[:created_at] = Sequel::CURRENT_TIMESTAMP if database.schema(table).assoc(:created_at)

        dataset.insert(record)
      end

      def copy(io, id, shrine_metadata: {}, **options)
        record_dataset = io.storage.find(io.id).select(:content, :metadata)
        record_dataset = record_dataset.select_append(Sequel::CURRENT_TIMESTAMP.as(:created_at)) if database.schema(table).assoc(:created_at)

        dataset.insert(record_dataset.columns, record_dataset)
      end

      def copyable?(io, id)
        io.is_a?(UploadedFile) && io.storage.is_a?(Storage::Sql)
      end

      def content(id)
        find(id).get(:content).to_s
      end

      def metadata(id)
        find(id).get(:metadata)
      end
    end
  end
end
