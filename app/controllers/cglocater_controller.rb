# coding: utf-8
require_relative './application_controller'
require_relative '../helpers/pg_connector'
require_relative '../searchers/pcg_searcher'

class CGLocaterController < ApplicationController
  RecPerPage = 16
  get '/' do
    if(session['email'].nil? or session['atime'].nil? or session['aid'].nil? or request.referer.nil? or params[:page].nil? or params[:city].nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    elsif(session['atime'] < Time.now-3600)
      slim :timeout, :locals => {:title => "授权时间已过！"}
    else
      aid = session['aid']
      useremail = session['email']
      page = params[:page].to_i
      city = params[:city].to_s
      dept = params[:department].to_s
      name = params[:pname].to_s
      reccount = params[:reccount].nil? ? -1 : params[:reccount].to_i
      if(page*RecPerPage>reccount && reccount>0)
        page = reccount / RecPerPage
      end
      locater = PCGSearcher.new(dq: city, dept: dept, pname: name)
      PgConnector.instance.make_query("INSERT INTO queries VALUES(DEFAULT, #{aid}, '#{useremail}', '#{Time.now}', 'cg', '#{city+' '+dept+' '+name}')")
      if(reccount==-1)
        startpos = locater.stmt.index('from')
        count_query = "select count(*) " + locater.stmt[startpos, locater.stmt.length]
        PgConnector.instance.make_query(count_query).each_row do |row|
          reccount = row[0].to_i
        end
      end
      if(reccount == 0)
        slim :'cglocater/no_match', :locals => {:title => "没找到哦！"}
      else
        locater.stmt = locater.stmt + " LIMIT #{RecPerPage} OFFSET #{page*RecPerPage}"
        locater.make_query
        # 生成翻页按钮
        purl = ""
        nurl = ""
        if(page > 0)
          purl = "./cglocater?page=#{page-1}&reccount=#{reccount}&city=#{city}"
          purl += "&department=#{dept}" if dept.length>0
          purl += "&pname=#{name}" if name.length>0
        end
        if(reccount > (page+1)*RecPerPage)
          nurl = "./cglocater?page=#{page+1}&reccount=#{reccount}&city=#{city}"
          nurl += "&department=#{dept}" if dept.length>0
          nurl += "&pname=#{name}" if name.length>0
        end
        slim :'cglocater/cg_result', :locals => {:title => "查询结果", :results => locater.results, :reccount => reccount, :purl => purl, :nurl => nurl }
      end
    end
  end
end

