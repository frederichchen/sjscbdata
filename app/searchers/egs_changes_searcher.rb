# coding: utf-8

require_relative '../helpers/pg_connector'

class EGSChangesSearcher
  attr_reader :stmt, :results

  def initialize(sv)
    @stmt = "select BGSXMC 变更项目, BGRQ 变更日期, BGQNR 变更前内容, BGHNR 变更后内容 from gsdjbgxx where ID='?'"
    @stmt.gsub!(/\?/, sv)
  end

  def make_query
    @results = PgConnector.instance.make_query(@stmt)
  end
end
