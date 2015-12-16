#!/usr/local/bin/ruby
# coding: utf-8

require 'pg'
require 'yaml'

class PgConnector
  attr_reader :dbh
  def initialize
    begin
      cnf = YAML.load(File.open(File.expand_path('../../../config', __FILE__) + "/database.yml"))
      @dbh = PG.connect(:host => cnf["PostgreSQL"]["host"], \
	                    :user => cnf["PostgreSQL"]["username"], \
	                    :password => cnf["PostgreSQL"]["password"], :dbname => "pinfo")
    rescue
      puts "Something's wrong with your database connection!"
    end
  end
  
  @@instance = PgConnector.new

  def self.instance
    return @@instance
  end

  def make_query(stmt)
    return @dbh.exec(stmt)
  end
  
  private_class_method :new
end
