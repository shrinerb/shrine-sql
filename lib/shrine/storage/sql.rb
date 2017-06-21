require "shrine"
require "sequel"

require "stringio"
require "json"

class Shrine
  module Storage
    class Sql
      attr_reader :database, :dataset

      def initialize(database:, table:)
        @database = database
        @dataset = @database[table]
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

      def multi_delete(ids)
        find(ids).delete
      end

      def url(id, **options)
      end

      def clear!
        dataset.delete
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

      def insert(io, id, shrine_metadata: {})
        dataset.insert(content: Sequel::SQL::Blob.new(io.read), metadata: shrine_metadata.to_json)
      end

      def copy(io, id, shrine_metadata: {})
        record = io.storage.find(io.id).select(:content, :metadata)
        dataset.insert([:content, :metadata], record)
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
