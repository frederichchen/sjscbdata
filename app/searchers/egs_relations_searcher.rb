# coding: utf-8

require_relative '../helpers/pg_connector'

class EGSRelationsSearcher
  attr_reader :stmts, :results

  def initialize(sv)
    @results = Array.new(2)
    @stmts = Array.new
    @stmts[0] = "select a.QYMC, a.FRDBXM, trim(a.FRZJHM_ZL), b.编制 from gsdjxx a left join czgy b on a.FRZJHM_ZL=b.sfz_zl where a.ID='#{sv}'"
    @stmts[1] = "select a.GDLXMC, a.GDMC, trim(a.GDZJHM_ZL), b.编制 from tzrczxx a left join czgy b on a.GDZJHM_ZL=b.sfz_zl where a.ID='#{sv}'"
    @stmts[2] = "select distinct 姓名, 身份证号, 编制 from hjinfoandczgy where 户号 in (select distinct 户号 from hjinfoandczgy where 身份证号='?') and 与户主关系<>'非亲属' and 身份证号<>'?'"
  end

  def make_query
    nodes = Array.new
    links = Array.new
    qymc = ''
    frzjhm = ''
    # 查询法人代表及其亲属
    PgConnector.instance.make_query(@stmts[0]).each_row do |row|
      qymc = row[0]
      frzjhm = row[2]
      nodes.push("{category: 0, name: '#{qymc}', value: 10}")
      if row[3].nil?
        nodes.push("{category: 1, name: '#{frzjhm}', label: '#{row[1]}', value: 3}")
      else
        nodes.push("{category: 1, name: '#{frzjhm}', label: '#{row[1]}(#{row[3]})', value: 3}")
      end
      links.push("{source: '#{qymc}', target: '#{frzjhm}', name: '法人代表'}")
      PgConnector.instance.make_query(@stmts[2].gsub(/\?/, frzjhm)).each_row do |qs|
        if qs[2].nil?
          nodes.push("{category: 4, name: '#{qs[1]}', label: '#{qs[0]}', value: 2}")
        else
          nodes.push("{category: 4, name: '#{qs[1]}', label: '#{qs[0]}(#{qs[2]})', value: 2}")
        end
        links.push("{source: '#{frzjhm}', target: '#{qs[1]}', name: '亲属'}")
      end
    end
    # 查询股东
    PgConnector.instance.make_query(@stmts[1]).each_row do |row|
      if row[0] == '20'
        if row[3].nil?
          nodes.push("{category: 2, name: '#{row[2]}', label: '#{row[1]}', value: 3}")
        else
          nodes.push("{category: 2, name: '#{row[2]}', label: '#{row[1]}(#{row[3]})', value: 3}")
        end
        links.push("{source: '#{qymc}', target: '#{row[2]}', name: '自然人股东'}")
        PgConnector.instance.make_query(@stmts[2].gsub(/\?/, row[2])).each_row do |qs|
          if qs[2].nil?
            nodes.push("{category: 4, name: '#{qs[1]}', label: '#{qs[0]}', value: 2}")
          else
            nodes.push("{category: 4, name: '#{qs[1]}', label: '#{qs[0]}(#{qs[2]})', value: 2}")
          end
          nodes.push("{category: 4, name: '#{qs[1]}', label: '#{qs[0]}', value: 2}")
          links.push("{source: '#{row[2]}', target: '#{qs[1]}', name: '亲属'}")
        end
      else
        nodes.push("{category: 3, name: '#{row[1]}', label: '#{row[1]}', value: 4}")
        links.push("{source: '#{qymc}', target: '#{row[1]}', name: '企业股东'}")
      end
    end
    @results[0] = '[' + nodes.join(",") + '];'
    @results[1] = '[' + links.join(",") + '];'
  end
end
