# coding: utf-8

require_relative '../helpers/pg_connector'

class PSBSearcher
  attr_reader :stmt, :results

  def initialize(sv)
    @stmt = "select DWMC 单位名称, ZJHM_ZL 身份证号15位, dq 地区, XM 姓名, CBNY 参保年月 from sb_personinfo where ZJHM_ZL='?'"
    @stmt.gsub!(/\?/, sv)
  end

  def make_query()
    @results = PgConnector.instance.make_query(@stmt)
  end
end
