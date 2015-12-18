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
        generated_id = dataset.insert(content: io.read, metadata: metadata.to_json)
        id.replace(generated_id.to_s)
      end

      def download(id)
        metadata = JSON.parse(metadata(id))
        extname = File.extname(metadata["filename"].to_s)
        tempfile = Tempfile.new(["shrine", extname], binmode: true)
        File.write(tempfile.path, content(id))
        tempfile
      end

      def open(id)
        StringIO.new(content(id))
      end

      def read(id)
        content(id)
      end

      def exists?(id)
        this = dataset.where(id: id).limit(1)
        !this.get(Sequel::SQL::AliasedExpression.new(1, :one)).nil?
      end

      def delete(id)
        dataset.where(id: id).delete
      end

      def multi_delete(ids)
        dataset.where(id: ids).delete
      end

      def url(id, options = {})
      end

      def clear!(confirm = nil)
        raise Shrine::Confirm unless confirm == :confirm
        dataset.delete
      end

      private

      def content(id)
        dataset.where(id: id).get(:content)
      end

      def metadata(id)
        dataset.where(id: id).get(:metadata)
      end
    end
  end
end
