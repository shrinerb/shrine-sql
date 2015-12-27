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

      def upload(io, id, metadata = {})
        generated_id = store(io, id, metadata)
        id.replace(generated_id.to_s + File.extname(id))
      end

      def download(id)
        tempfile = Tempfile.new(["shrine", File.extname(id)], binmode: true)
        File.write(tempfile.path, content(id))
        tempfile
      end

      def stream(id)
        yield content(id)
      end

      def open(id)
        StringIO.new(content(id))
      end

      def read(id)
        content(id)
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

      def clear!(confirm = nil)
        raise Shrine::Confirm unless confirm == :confirm
        dataset.delete
      end

      protected

      def find(id_or_ids)
        ids = Array(id_or_ids).map { |s| File.basename(s, ".*") }
        dataset.where(id: ids).limit(ids.count)
      end

      private

      def store(io, id, metadata)
        if copyable?(io, id)
          copy(io, id, metadata)
        else
          insert(io, id, metadata)
        end
      end

      def insert(io, id, metadata)
        dataset.insert(content: io.read, metadata: metadata.to_json)
      end

      def copy(io, id, metadata)
        record = io.storage.find(io.id).select(:content, :metadata)
        dataset.insert([:content, :metadata], record)
      end

      def copyable?(io, id)
        io.is_a?(UploadedFile) && io.storage.is_a?(Storage::Sql)
      end

      def content(id)
        find(id).get(:content)
      end

      def metadata(id)
        find(id).get(:metadata)
      end
    end
  end
end
