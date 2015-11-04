# active_record [![Build Status](https://travis-ci.org/waterlink/active_record.cr.svg?branch=master)](https://travis-ci.org/waterlink/active_record.cr)

Active Record pattern implementation for Crystal.

Don't confuse with Ruby's activerecord: aim of this is to be true to OO techniques and true to the Active Record pattern. Small, simple, useful for non-complex domain models. For complex domain models better use Data Mapper pattern.

**Work in progress**

## TODO

- [x] Implement model definition syntax
- [x] Implement `field_level`
- [x] Implement `NullAdapter` (in-memory, for specs)
- [x] Implement `#create`, `.create` and `.get`
- [x] Implement `.where`
- [x] Implement `query_level`
- [x] Implement `#update` and `#delete`
- [x] Implement better query DSL
- [x] Default `table_name` implementation
- [x] Implement `mysql` adapter
- [x] Populate this list further by making some simple app on top of it
- [x] Describe in readme how to implement your own adapter
- [ ] Add transaction features
- [ ] Implement `postgres` driver and adapter and set it to default
- [ ] Implement `sqlite` driver and adapter
- [ ] Support more types (currently only Int|String are supported)

## Installation

Add it to `shard.yml`:

```yaml
dependencies:
  active_record:
    github: waterlink/active_record.cr
    version: 0.1.1
```

## Usage

```crystal
require "active_record"
```

### Define your model

```crystal
class Person < ActiveRecord::Model

  # Set adapter, defaults to mysql (subject to change to postgres)
  # adapter sqlite

  # Set table name, defaults to "#{lowercase_name}s"
  # table_name people

  # Database fields
  primary id                 :: Int
  field last_name            :: String
  field first_name           :: String
  field number_of_dependents :: Int

  # Domain logic
  def get_tax_exemption
    # ...
  end

  def get_taxable_earnings
    # ...
  end

end
```

### Create a new record

```crystal
# Combine .new(..) and #create
Person.new({ "first_name"           => "John",
             "last_name"            => "Smith",
             "number_of_dependents" => 3 }).create #=> #<Person: ...>

# Or shortcut with .create(..)
Person.create({ "first_name"           => "John",
                "last_name"            => "Smith",
                "number_of_dependents" => 3 })     #=> #<Person: ...>
```

### Get existing record by id

```crystal
Person.get(127)  #=> #<Person: @id=127, ...>
```

### Query multiple records

```crystal
# Get all records
Person.all         # => [#<Person: ...>, #<Person: ...>, ...]

# Query by hash
Person.where({ "number_of_dependents" => 0 })   #=> [#<Person: ...>, #<Person: ...>, ...]

# Or construct a query object
include ActiveRecord::CriteriaHelper
Person.where(criteria("number_of_dependents") > 3)    #=> [#<Person: ...>, #<Person: ...>, ...]
```

See [Query DSL](#query-dsl)

### Update existing record

```crystal
person = Person.get(127)
person.number_of_dependents = 0
person.update
```

### Delete existing record

```crystal
Person.get(127).delete
```

### Enforcing encapsulation

If you care about OO techniques, code quality and handling complexity, please enable this for your models.

```crystal
class Person < ActiveRecord::Model

  # Default is public for ease of use
  field_level :private
  # field_level :protected

  query_level :private
  # default is public, there is no point in protected here

  # ...
end

# Enforces you to maintain encapsulation, ie: not expose your data -
# put behavior in the same place the data it needs
person = Person.get(127)    # or Person[127]
person.first_name   #=> Error: unable to call private method first_name

# Enforces you to maintain DRYness to some extent, ie: not leak
# knowledge about your database structure, but put it in active record
# model and expose your own nit-picked methods
Person.where({ :first_name => "John" })    #=> Error: unable to call private method where
```

### Query DSL

Generally to use `#criteria` DSL method, you need to `include
ActiveRecord::CriteriaHelper`, but inside of your model code you
don't need to do that.

Examples (comment is in format `[sql_query, params]`):

```crystal
criteria("person_id") == 3                            # [person_id = :1, { "1" => 3 }]
criteria("person_id") == criteria("other_person_id")  # [person_id = other_person_id, {}]

criteria("number") <= 3                               # [number < :1, { "1" => 3 }]

(!(criteria("number") <= 3))                          # [(NOT (number <= :1)) AND (number <> :2),
  .and(criteria("number") != 5)                       #  { "1" => 3, "2" => 5 }]

criteria("subject_id").is_not_null                    # [(subject_id) IS NOT NULL, {}]
```

Supported comparison operators: `== != > >= < <=`

Supported logic operators: `or | and & xor ^ not !`

Supported is operators: `is_true is_not_true is_false is_not_false is_unknown is_not_unknown is_null is_not_null`

## Development

After cloning the project:

```
cd active_record.cr
crystal deps   # install dependencies
crystal spec   # run specs
```

Just use normal TDD development style.

### Creating your own database adapter

So, lets create a postgres adapter. First lets init the repo:

```bash
# This creates 'postgres_adapter' library and names directory as 'postgres_adapter.cr'.
# Effectively giving you structure './postgres_adapter.cr/src/mysql_adapter.cr'.
crystal init lib postgres_adapter postgres_adapter.cr

# And lets cd into it right away:
cd postgres_adapter.cr/
```

Next feel free to edit the README to reflect the usage as you see fit. And
check out if generated LICENSE file is OK.

At this point it is a good idea to make an initial commit to git and push your
changes to Github (or whatever git upstream you use).

Before the next step you will need `active_record` bundled as a submodule at
path `modules/active_record`, for that you do:

```bash
git submodule add https://github.com/waterlink/active_record.cr modules/active_record
```

You need to have it as a submodule to be able to require code from `spec/` directory.

Next step is to add appropriate integration test boilerplate:

Integration spec:

```crystal
# integration/integration_spec.cr
require "./spec_helper"
```

Integration spec helper:

```crystal
# integration/spec_helper.cr
require "spec"
require "../src/postgres_adapter"
require "active_record/null_adapter"

# Register our adapter as 'null' adapter, effectively overriding what was
# registered before by 'active_record':
ActiveRecord::Registry.register_adapter("null", PostgresAdapter::Adapter)

# Cleanup database before and after each example:
Spec.before_each do
  PostgresAdapter::Adapter._reset_do_this_only_in_specs_78367c96affaacd7
end
Spec.after_each do
  PostgresAdapter::Adapter._reset_do_this_only_in_specs_78367c96affaacd7
end

# Require fake adapter and kick off the integration spec
require "../modules/active_record/spec/fake_adapter"
require "../modules/active_record/spec/active_record_spec"
```

Integration test runner script:

```bash
# bin/test
#!/usr/bin/env bash

set -e

# Run unit tests
crystal spec

# Compile integration tests that are shipped with
crystal build integration/integration_spec.cr -o integration/integration_spec -D active_record_adapter
./integration/integration_spec --fail-fast -v $*
```

Script for setting up the database:

```bash
# script/setup-test-db.sh
#!/usr/bin/env bash

# By providing 'PG_USER' and ('PG_PASS' or `PG_ASK_PASS`) you can
# control how this script will authenticate to local pg server.
PARAMS="-U ${PG_USER:-postgres}"
[[ -z "$PG_PASS" ]] || PGPASSWORD="$PG_PASS"
[[ -z "$PG_ASK_PASS" ]] || PARAMS="$PARAMS -W"

psql $PARAMS -c "create database crystal_pg_test"
psql $PARAMS -c "create user crystal_pg with superuser password 'crystal_pg'"

psql $PARAMS crystal_pg_test -c "drop table if exists people; create table people( id serial primary key, last_name varchar(50), first_name varchar(50), number_of_dependents int )"
psql $PARAMS crystal_pg_test -c "drop table if exists something_else; create table something_else( id serial primary key, name varchar(50) )"
psql $PARAMS crystal_pg_test -c "drop table if exists posts; create table posts( id serial primary key, title varchar(50), content text, created_at timestamp )"
```

Make all scripts executable:

```bash
chmod a+x bin/test
chmod a+x script/setup-test-db.sh
```

And setup test db:

```bash
script/setup-test-db.sh
```

If you run tests at this point with `bin/test`, you should get compile error,
since you have not implemented `ActiveRecord::Adapter` protocol. You can find
it [here](/src/adapter.cr).

First make some stub implementation for this protocol:

```crystal
# src/postgres_adapter.cr
require "active_record"
require "active_record/adapter"

module PostgresAdapter
  class Adapter < ActiveRecord::Adapter
    def self.build(table_name, primary_field, fields, register = true)
      new(table_name, primary_field, fields, register)
    end

    def self.register(adapter)
      adapters << adapter
    end

    def self.adapters
      (@@_adapters ||= [] of self).not_nil!
    end

    getter table_name, primary_field, fields

    def initialize(@table_name, @primary_field, @fields, register = true)
      self.class.register(self)
    end

    def create(fields)
      0
    end

    def get(id)
      nil
    end

    def all
      [] of Hash(String, ActiveRecord::SupportedType)
    end

    def where(query_hash : Hash)
      all
    end

    def where(query : ActiveRecord::Query)
      all
    end

    def update(id, fields)
    end

    def delete(id)
    end

    # Resets all data for all registered adapter instances of this kind
    def self._reset_do_this_only_in_specs_78367c96affaacd7
      adapters.each &_reset_do_this_only_in_specs_78367c96affaacd7
    end

    # Resets all data for current table (adapter instance)
    def _reset_do_this_only_in_specs_78367c96affaacd7
    end
  end
end
```

Of course you need to include `active_record` as a dependency in your `shard.yml`:

```yml
dependencies:
  active_record:
    github: waterlink/active_record.cr
```

To install it, run `shards` or `crystal deps`.

With this boilerplate you should have actually compiled integration test and it
should be RED. Next step would be to follow TDD and make it green
example-by-example while replacing stub implementation with real one.

When you are done, congratulate yourself and push first release (git tag) to
Github (or whatever git upstream you use).

Don't forget to register your adapter:

```crystal
# At the end of src/postgres_adapter.cr
ActiveRecord::Registry.register_adapter("postgres", PostgresAdapter::Adapter)
```

Congratulations, you made it!

## Contributing

1. Fork it ( https://github.com/waterlink/active_record.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [waterlink](https://github.com/waterlink) Oleksii Fedorov - creator, maintainer
