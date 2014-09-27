require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ..
    return @columns if @columns
    cols = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    @columns = cols[0].map(&:to_sym)
  end

  def self.finalize!
    #creating getting and setter for each class
    self.columns.each do |name|
      define_method(name) { self.attributes[name] }
      define_method("#{name}=") {|value| self.attributes[name] = value}
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name ||= self.name.underscore.pluralize
  end

  def self.all
    # ...
    results = DBConnection.execute(<<-SQL)
    SELECT
    #{table_name}.*
    FROM
    #{table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    # ...
    #convert all query result into new SQLObject
    results.map { |result| self.new(result)}
  end

  def self.find(id)
    # ...
    results = DBConnection.execute(<<-SQL, id)
    SELECT
      #{table_name}
    FROM
      #{ table_name }
    WHERE
      #{ table_name }.id = ?
    SQL

    parse_all(results).first
    #return only the first result, 
    #intiailly i tried with Limit 1 in the query it didn't work for some reason
  end

  def initialize(params = {})
    # ...
    params.each do |attr_name, value|
      if self.class.columns.include?(att_name)
        self.send("#{ attr_name }", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end

  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    # ...
    self.class.columns.map { |attr_name| self.send(attr_name)}
  end

  def insert
    # ...
    col_names = self.class.columns.map(&:to_s).join(',')
    question_marks = Array.new(self.class.columns, "?").join(',')

    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      ( #{question_marks} )
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
    set_line = self.class.columns.map { |attr| "#{attr} = ?" }.join(",")

    DBConnection.execute(<<-SQL, *attribute_values, id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      #{self.class.table_name}.id = ?
    SQL

  end

  def save
    # ...
    if  id.nils? 
      insert
    else
      update
    end
  end
end
