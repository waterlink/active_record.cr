# active_record

Active Record pattern implementation for Crystal.

Don't confuse with Ruby's activerecord: aim of this is to be true to OO techniques and true to the Active Record pattern. Small, simple, useful for non-complex domain models. For complex domain models better use Data Mapper pattern.

**Work in progress**

## Installation

Add it to `Projectfile`

```crystal
deps do
  github "waterlink/active_record.cr"
end
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

### Create new record

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

### Read existing record by id

```crystal
Person.read(127)  #=> #<Person: @id=127, ...>
```

### Query multiple records

```crystal
# Query by hash
Person.where({ "number_of_dependents" => 0 })   #=> [#<Person: ...>, #<Person: ...>, ...]

# Or use parametrized SQL (if you use SQL adapter of course)
Person.where("number_of_dependents > :min_dependents",
             { "min_dependents" => 3 })    #=> [#<Person: ...>, #<Person: ...>, ...]
```

### Update existing record

```crystal
person = Person.read(127)
person.number_of_dependents = 0
person.update
```

### Delete existing record

```crystal
Person.read(127).delete
```

### Enforcing encapsulation

If you care about OO techniques, code quality and handling complexity, please enable this for you models.

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
person = Person.find(127)
person.first_name   #=> Error: unable to call private method first_name

# Enforces you to maintain DRYness to some extent, ie: not leak
# knowledge about your database structure, but put it in active record
# model and expose your own nit-picked methods
Person.where({ :first_name => "John" })    #=> Error: unable to call private method where
```

## Development

TODO: Write instructions for development

## Contributing

1. Fork it ( https://github.com/waterlink/active_record.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [waterlink](https://github.com/waterlink) Oleksii Fedorov - creator, maintainer
