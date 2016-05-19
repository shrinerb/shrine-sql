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
create_table :files do
  primary_key :id
  column :content, :text # :bytea for PostgreSQL, :blob for MySQL
  column :metadata, :text # :varchar
end
```

We can now instantiate the storage with a `Sequel::Database` and the name of
the table:

```rb
require "shrine/storage/sql"
require "sequel"

DB = Sequel.connect("postgres:///my-database")
Shrine.storages[:store] = Shrine::Storage::Sql.new(database: DB, table: :files)
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
  mount Shrine::DownloadEndpoint => "/attachments"
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
