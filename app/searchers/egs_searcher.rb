# coding: utf-8

require_relative '../helpers/pg_connector'

class EGSSearcher
  attr_reader :stmt, :results
  
  def initialize(sv, fuzzy)
    @stmt = "select ID, QYMC 企业名称, ZS 住所, QYZT 状态, FRDBXM 法人, FRZJHM_ZL 法人证件号码 from gsdjxx where QYMC "
    if(fuzzy==0)
      @stmt = @stmt + "='?' LIMIT 50"
    else
      @stmt = @stmt + "like '%?%' LIMIT 50"
    end
    @stmt.gsub!(/\?/, sv)
  end

  def make_query
    @results = PgConnector.instance.make_query(@stmt)
  end
end
