# coding: utf-8

require_relative '../helpers/pg_connector'

class PGSSearcher
  attr_reader :stmt, :results

  def initialize(sv)
    @stmt = "select ID, QYMC 企业名称, '法人' 身份, FRDBXM 姓名, FRZJHM 证件号码 from gsdjxx where FRZJHM_ZL='?' union all select a.ID, QYMC 企业名称, '股东' 身份, GDMC 姓名, GDZJHM 证件号码 from tzrczxx a, gsdjxx b where GDZJHM_ZL='?' and a.ID=b.ID"
    @stmt.gsub!(/\?/, sv)
  end

  def make_query()
    @results = PgConnector.instance.make_query(@stmt)
  end
end
