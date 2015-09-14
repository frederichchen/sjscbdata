# coding: utf-8

require_relative '../helpers/pg_connector'

class PDSSearcher
  attr_reader :stmt, :results

  def initialize(sv)
    @stmt = "select FFYF 月份, XM 姓名, ZZHM_ZL 十五位身份证号, GZDW 工作单位, SRE 收入额, SL 税率, SJYNSE 应纳税额 from ds_gs2013 where ZZHM_ZL='?'"
    @stmt.gsub!(/\?/, sv)
  end

  def make_query()
    @results = PgConnector.instance.make_query(@stmt)
  end
end
