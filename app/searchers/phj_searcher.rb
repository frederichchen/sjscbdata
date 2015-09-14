# coding: utf-8

require_relative '../helpers/pg_connector'

class PHJSearcher
  attr_reader :stmt, :results

  def initialize(sv)
    @stmt = "select distinct * from (select '当前情况' as 来源, sfzh 身份证号, sbxm 姓名, xxhh 户号, gx 与户主关系 from hj_familyinfo where xxhh in (select distinct xxhh from hj_familyinfo where sfzh='?') and gx<>'非亲属' union (select '迁移情况' as 来源, sfzh_zl, czrkxm, xxhh, hnsf from hcybd where xxhh in (select distinct xxhh from hcybd where sfzh_zl='?') and hnsf<>'非亲属')) as a order by 来源, 户号"
    @stmt.gsub!(/\?/, sv)
  end

  def make_query()
    @results = PgConnector.instance.make_query(@stmt)
  end
end
