require_relative "../config/environment.rb"
require 'active_support/inflector'
# where is this active_support directory? I don't see it...

class Song

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info('#{table_name}')"
    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |column|
      column_names << column["name"]
      end
    column_names.compact #compact cleans any nil values
    # returns array of column names
  end

  # generates attr_accessor statement dynamically:
  self.column_names.each do |name|
    attr_accessor name.to_sym
    end

  # takes in a hash and assigns them to the initialzing instance
  def initialize (options = {})
    options.each do |attribute, value|
      self.send("#{attribute}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
    # makes table_name useful within instance methods by adding self.class
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(",")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col|
      values << "'#{send(col)}'" unless send(col).nil?
      end
    values.join(",")
  end

  def save # see below for riskier but fully dynamic version
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (?,?)", [values_for_insert])
      # why the brackets around values_for_insert?
      # I bet the "?/?,?" was removed because it's not truly abstracted and depends on the correct number of question marks being there
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name (name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?, [name]")
      # again, why the brackets?
  end

  # def save
  #   sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
  #   DB[:conn].execute(sql)
  #   @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  # end

end
