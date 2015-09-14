# coding: utf-8
require_relative './application_controller'
require_relative '../helpers/pg_connector'
require_relative '../searchers/egs_searcher'
require_relative '../searchers/egs_detail_searcher'
require_relative '../searchers/egs_changes_searcher'

class ELocaterController < ApplicationController
  get '/' do
    if(session['email'].nil? or session['atime'].nil? or session['aid'].nil? or request.referer.nil? or params[:searchvalue].nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    elsif(session['atime'] < Time.now-3600)
      slim :timeout, :locals => {:title => "授权时间已过！"}
    else
      locations = ["四川", "四川省", "成都", "成都市", "自贡", "自贡市", "攀枝花", "攀枝花市", "泸州", "泸州市", "德阳", "德阳市", "绵阳", "绵阳市", "广元", "广元市", "遂宁", "遂宁市", "内江", "内江市", "乐山", "乐山市", "南充", "南充市", "眉山", "眉山市", "宜宾", "宜宾市", "广安", "广安市", "达州", "达州市", "雅安", "雅安市", "巴中", "巴中市", "资阳", "资阳市", "阿坝", "甘孜", "凉山"]
      aid = session['aid']
      useremail = session['email']
      sv = params[:searchvalue]
      type = params[:type]
      errors=Array.new()
      errors.push("企业名称为空！") if sv.length==0
      errors.push("输入的企业名称太短！") if sv.length <= 2
      errors.push("请输入企业名称而不是地域名称！") if locations.include? sv
      errors.push("搜索类型不对！") if type != 'gs' and type != 'ds' and type != 'zh'
      if errors.count > 0
        slim :'portal/esearch', :locals => {:title => "输入有误", :stylesheets => ["bootstrap-select.min"], :scripts => ["bootstrap-select.min", "select.settings"], :errors => errors}
      else
        fuzzy = params[:fuzzy]=="yes" ? 1 : 0
        PgConnector.instance.make_query("INSERT INTO queries VALUES(DEFAULT, #{aid}, '#{useremail}', '#{Time.now}', '#{'e-'+type}', '#{sv}')")
        locater = Kernel.const_get("E"+type.upcase+"Searcher").new(sv, fuzzy)
        locater.make_query
        if locater.results.count == 0
          slim :'elocater/no_match', :locals => {:title => "没找到哦！"}
        else
          slim :"elocater/#{type}_result", :locals => {:title => "查询结果", :sv => sv, :results => locater.results}
        end
      end
    end
  end

  # 工商登记详细信息
  get '/gsdetail' do
    if(session['email'].nil? or session['atime'].nil? or session['aid'].nil? or request.referer.nil? or params[:searchvalue].nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      sv = params[:searchvalue]
      aid = session['aid']
      useremail = session['email']
      PgConnector.instance.make_query("INSERT INTO queries VALUES(DEFAULT, #{aid}, '#{useremail}', '#{Time.now}', 'e-gsid', '#{sv}')")
      locater = EGSDetailSearcher.new(sv)
      locater.make_query
      slim :'elocater/gs_detail_result', :locals => {:title => "工商登记情况", :sv => sv, :results => locater.results}
    end
  end

  # 工商登记变更信息
  get '/gschanges' do
    if(session['email'].nil? or session['atime'].nil? or session['aid'].nil? or request.referer.nil? or params[:searchvalue].nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      sv = params[:searchvalue]
      locater = EGSChangesSearcher.new(sv)
      locater.make_query
      slim :'elocater/gs_changes_result', :locals => {:title => "工商登记变更情况", :sv => sv, :results => locater.results}
    end
  end
end
