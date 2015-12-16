# coding: utf-8

require_relative '../helpers/pg_connector'

class PZHSearcher
  attr_reader :stmts, :results

  def initialize(sv)
    @stmts = Array.new(5)
    @stmts[0] = "select distinct DWMC from sb_personinfo where ZJHM_ZL='#{sv}' and DWMC is not null limit 5"
    @stmts[1] = "select distinct 身份证号, 姓名 from hjinfoandczgy where 户号 in (select 户号 from hjinfoandczgy where 身份证号='#{sv}') and 与户主关系<>'非亲属'"
    @stmts[2] = "select QYMC from gsdjxx where FRZJHM_ZL='#{sv}' union all select QYMC from gsdjxx where ID in (select ID from tzrczxx where GDZJHM_ZL='#{sv}')"
    @stmts[3] = "select FFYF, GZDW, SJYNSE from ds_gs2013 where ZZHM_ZL='#{sv}' limit 3"
    @stmts[4] = "select 工作单位, 职务, 状态 from czgy where sfz_zl='#{sv}'"
    @results = Array.new(5)
  end

  def make_query
    results[0] = "社保缴纳单位： "
    PgConnector.instance.make_query(@stmts[0]).each_row do |row|
      results[0] += "#{row[0]}\n"
    end
    if(results[0].length == 8)
      results[0] = nil
    else
      results[0] += '……'
    end
    
    results[1] = "同一户中的亲属： "
    PgConnector.instance.make_query(@stmts[1]).each_row do |row|
      results[1] += "#{row[1]}(#{row[0]})\n"
    end
    if(results[1].length == 9)
      results[1] = nil
    end
    
    results[2] = "担任法人或股东的单位： "
    PgConnector.instance.make_query(@stmts[2]).each_row do |row|
      results[2] += "#{row[0]}\n"
    end
    if(results[2].length == 12)
      results[2] = nil
    end
    
    results[3] = "个税缴纳信息： "
    PgConnector.instance.make_query(@stmts[3]).each_row do |row|
      results[3] += "年月#{row[0]}，在#{row[1]}缴纳个税#{row[2]}元；\n"
    end
    if(results[3].length == 8)
      results[3] = nil
    else
      results[3] += '……'
    end
    
    results[4] = ""
    PgConnector.instance.make_query(@stmts[4]).each_row do |row|
      results[4] += "所在单位为#{row[0]}，职务是#{row[1]}，状态是#{row[2]}\n"
    end
    if(results[4].length == 0)
      results[4] = nil
    end
  end
end
