# coding: utf-8
require_relative './application_controller'
require_relative '../helpers/pg_connector'
require_relative '../searchers/pcg_searcher'
require_relative '../searchers/pds_searcher'
require_relative '../searchers/pgs_searcher'
require_relative '../searchers/phj_searcher'
require_relative '../searchers/psb_searcher'
require_relative '../searchers/pzh_searcher'

class PLocaterController < ApplicationController
  get '/' do
    if(session['email'].nil? or session['atime'].nil? or session['aid'].nil? or request.referer.nil? or params[:searchvalue].nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    elsif(session['atime'] < Time.now-3600)
      slim :timeout, :locals => {:title => "授权时间已过！"}
    else
      aid = session['aid']
      useremail = session['email']
      sv = params[:searchvalue].length==18 ? params[:searchvalue].slice(0,6)+params[:searchvalue].slice(8,9) : params[:searchvalue]
      type = params[:type]
      errors=Array.new()
      errors.push("身份证号为空！") if sv.length==0
      errors.push("身份证号长度不是15位或18位！") if sv.length!=15
      errors.push("搜索类型不对！") if type != 'sb' and type != 'hj' and type != 'gs' and type != 'ds' and type != 'cg' and type != 'zh'
      if errors.count > 0
        slim :'portal/psearch', :locals => {:title => "输入有误", :stylesheets => ["bootstrap-select.min"], :scripts => ["bootstrap-select.min", "select.settings"], :errors => errors}
      else
        PgConnector.instance.make_query("INSERT INTO queries VALUES(DEFAULT, #{aid}, '#{useremail}', '#{Time.now}', '#{'p-'+type}', '#{sv}')")        
        # 财政供养人员的searcher参数不同，因此需要单独生成
        if type == 'cg'
          locater = PCGSearcher.new(sfz: sv)
        else
          locater = Kernel.const_get("P"+type.upcase+"Searcher").new(sv)
        end
        locater.make_query
        if locater.results.count == 0
          slim :'plocater/no_match', :locals => {:title => "没找到哦！"}
        else
          slim :"plocater/#{type}_result", :locals => {:title => "查询结果", :scripts => ["excellentexport"], :sv => sv, :results => locater.results}
        end
      end
    end
  end
end