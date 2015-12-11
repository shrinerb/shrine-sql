# Shrine::Sql

Provides a [Shrine] storage for storing files in any SQL database. It uses
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
  column :content, :text
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

The shrine-sql storage itself doesn't provide any kind of URL, but you can load
the `data_uri` plugin, which provides `UploadedFile#data_uri` which returns the
data URI of the file, which you can display in the browser:

```rb
Shrine.plugin :data_uri
```
```rb
user.avatar.data_uri #=> "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA"
```

Note that `UploadedFile#data_uri` is only available in Shrine >= 1.1.

### Indices

It is recommended that you add a unique index to the "id" column, for faster
lookups. Depending on your needs, you can also make the primary key column a
UUID type, if your database supports it.

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
