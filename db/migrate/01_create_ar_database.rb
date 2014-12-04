require "active_record"

class CreateArDatabase < ActiveRecord::Migration
  def change
    create_table :repos do |t|
      t.string :url
    end

    create_table :metrics do |t|
      t.string :name
    end

    # date-repo-metric is a composite primary key,
    # but we don't want to depend on an extension for that:
    # https://github.com/composite-primary-keys/composite_primary_keys
    create_table :measurements do |t|
      t.date       :date
      t.references :repo
      t.references :metric
      t.float      :value
    end
  end
end

if false
  ActiveRecord::Base.establish_connection(adapter:  "sqlite3",
                                          database: "test.sqlite3")
  CreateArDatabase.migrate :up
end
