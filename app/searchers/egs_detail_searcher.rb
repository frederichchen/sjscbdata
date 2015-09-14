# coding: utf-8

require_relative '../helpers/pg_connector'

class EGSDetailSearcher
  attr_reader :stmts, :results
  
  def initialize(sv)
    @stmts = Array.new(2)
    @stmts[0] = "select QYMC 企业名称, QULXMC 企业类型, YYZZHM 营业执照号码, ZCZB 注册资本, QYCLRQ 成立日期, ZS 住所, QYZT 状态, DJJGMC 登记机关, JYFW 经营范围, FRDBXM 法人, FRZJHM_ZL 法人证件号码 from gsdjxx where ID='?'"
    @stmts[0].gsub!(/\?/, sv)
    @stmts[1] = "select GDMC 股东名称, GDZJHM_ZL 股东证件号码, GDLXMC 股东类型 from tzrczxx where ID='?'"
    @stmts[1].gsub!(/\?/, sv)
    @results = Array.new(2)
  end

  def make_query
    PgConnector.instance.make_query(stmts[0]).each_row do |row|
      @results[0] = row.collect do |element|
        if element.class=="BigDecimal"
          element.to_s('F')
        else
          element
        end
      end
    end
    @results[1] = PgConnector.instance.make_query(stmts[1])
  end
end
