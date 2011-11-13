require "active_record"
require "active_support/core_ext/string"

class Temping
  class << self
    def create(model_name, &block)
      connect unless ActiveRecord::Base.connected?

      model_class = model_name.to_s.classify
      unless eval("defined?(#{model_class})")
        factory = ModelFactory.new(model_class, &block)
        factory.klass
      end
    end

    private

    def connect
      options = { :adapter => "sqlite3", :database => ":memory:" }

      ActiveRecord::Base.configurations["temping"] = options
      ActiveRecord::Base.establish_connection("temping")
    end
  end

  class ModelFactory
    attr_reader :klass

    def initialize(model_name, &block)
      @klass = Class.new(ActiveRecord::Base)

      Object.const_set(model_name, @klass)
      create_table
      add_methods
      @klass.class_eval(&block) if block_given?
    end

    private

    def create_table
      connection.create_table(table_name, :temporary => true) do |table|
        table.integer :id
      end
    end

    def add_methods
      class << @klass
        def with_columns
          connection.change_table(table_name) do |table|
            yield(table)
          end
        end

        def table_exists?
          true
        end
      end
    end

    def connection
      @klass.connection
    end

    def table_name
      @klass.table_name
    end
  end
end
