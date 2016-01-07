# coding: utf-8

require_relative '../helpers/pg_connector'

class PHJSearcher
  attr_reader :stmt, :results

  def initialize(sv)
    @stmt = "select distinct * from (select 姓名, 身份证号, 户号, 与户主关系 from hjinfoandczgy where 户号 in (select 户号 from hjinfoandczgy where 身份证号='?') and 与户主关系<>'非亲属') a order by 户号"
    @stmt.gsub!(/\?/, sv)
  end

  def make_query()
    @results = PgConnector.instance.make_query(@stmt)
  end
end
