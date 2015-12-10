# coding: utf-8

require_relative '../helpers/pg_connector'

class PCGSearcher
  attr_reader :results
  attr_accessor :stmt

  def initialize(sfz: '', dq: '', dept: '', pname: '')
    @stmt = "select 地区名称, 工作单位, 姓名, v060426113903 身份证号, 职务, 学历, 状态, 编制 from czgy where "
    filters = Array.new
    filters.push("sfz_zl='#{sfz}'") if sfz != ''
    filters.push("substring(地区代码,1,4)='#{dq}'") if dq != ''
    filters.push("工作单位 like '%#{dept}%'") if dept != ''
    filters.push("姓名='#{pname}'") if pname != ''
    @stmt = @stmt + filters.join(" and ")
  end

  def make_query()
    @results = PgConnector.instance.make_query(@stmt)
  end
end
