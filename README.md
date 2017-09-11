# Shrine::Storage::Sql

Provides [Shrine] storage for storing files in any SQL database. It uses
[Sequel] under the hood.

## Installation

```ruby
gem "shrine-sql"
```

## Usage

We first need to create the table for our files, with "id" and "content" columns:

```rb
# for Sequel users
Sequel.migration do
  change do
    create_table :files do
      primary_key :id
      File :content
      String :metadata, text: true
      Time :created_at
    end
  end
end
```
```rb
# for ActiveRecord users
class CreateFiles < ActiveRecord::Migration
  def change
    create_table :files do |t|
      t.binary :content
      t.text :metadata
      t.datetime :created_at
    end
  end
end
```

We should instantiate the storage with a `Sequel::Database` object and the
name of the table, regardless of the ORM you're actually using in your app.

```rb
require "shrine/storage/sql"
require "sequel"

DB = Sequel.connect("postgres:///my-database")
Shrine::Storage::Sql.new(database: DB, table: :files)
```

You can see [Connecting to a database] on how connect to any database with
Sequel.

### URL

By itself shrine-sql doesn't provide URLs to files, but they can be streamed
via a URL with the `download_endpoint` plugin:

```rb
# Assuming :store uses the SQL storage.
Shrine.plugin :download_endpoint, storages: [:store]
```
```rb
Rails.application.routes.draw do
  mount Shrine.download_endpoint => "/attachments"
end
```
```rb
user.avatar_url #=> "/attachments/store/938432984643.jpg"
```

### Indices

It is recommended that you add a unique index to the "id" column, for faster
lookups.

## Copying

If you're using the SQL storage for both cache and store, moving from cache to
store will copy the record using SQL instead "reuploading" it, which means the
file contents won't be read into memory.

## Clearing

You can delete all data from the storage via `Shrine::Storage::Sql#clear!`:

```rb
sql = Shrine::Storage::Sql.new(database: DB, table: :files)
sql.clear!
```

If you're using SQL as temporary storage, you can clear old files by passing
a block to `#clear!` and querying the `created_at` column:

```rb
sql.clear! { |dataset| dataset.where{created_at < Time.now - 7*24*60*60} }
```

## Contributing

You can run the tests with Rake:

```sh
$ bundle exec rake test
```

## License

[MIT](http://opensource.org/licenses/MIT)

[Shrine]: https://github.com/janko-m/shrine
[Sequel]: https://github.com/janko-m/shrine
[Connecting to a database]: http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html
