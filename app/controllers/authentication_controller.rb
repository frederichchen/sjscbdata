# coding: utf-8
require 'base64'
require 'digest/md5'
require_relative './application_controller'
require_relative '../helpers/pg_connector'

class AuthenticationController < ApplicationController
  RecPerPage = 20
  # 计算机处人员和办领导验证环节
  get '/suquery' do
    if(params[:useremail].nil? or params[:qpass].nil? or request.referer.nil? or (params[:usertype] != '1' and params[:usertype] != '2'))
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      useremail = params[:useremail]
      usertype = params[:usertype]
      qpass = Digest::MD5.hexdigest(params[:qpass])
      digest = Base64.urlsafe_encode64(useremail+"|-#{usertype}|"+Time.now.to_s.slice(0,19))
      if((qpass == '1915b79997517203fbd3fdbded9fc581' and usertype == '2') or (qpass == '810637d5c11dccb9cbbbad4d6af4debc' and usertype == '1'))
        "{\"success\":true, \"digest\":\"#{digest}\"}"     # 认证成功
      else
        "{\"success\":false, \"digest\":\"#{digest}\"}"    # 认证失败
      end
    end
  end

  # 一般人员提交查询申请环节
  post '/submitapplication' do
    if(params[:lock].nil? or params[:applicant].nil? or params[:content].nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      useremail = params[:email].to_s
      userdid = params[:did].to_s
      seclock = params[:lock]
      content = params[:content]
      PgConnector.instance.make_query("INSERT INTO approvals VALUES(DEFAULT, '#{useremail}', '#{userdid}', NULL, '#{content}', '#{Time.now}', NULL, NULL, 1)")
      redirect url("./checkapplication?lock=#{seclock}")
    end
  end

  # 一般人员查看申请审批情况环节
  get '/checkapplication' do
    if(params[:lock].nil? or request.referer.nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      @seclock = params[:lock]
      # 清理一下首次使用到现在超过一小时的申请，即已经过期的申请。
      PgConnector.instance.make_query("UPDATE approvals SET state='0' WHERE stime IS NOT NULL AND stime<'#{Time.now-3600}'")
      @applications = PgConnector.instance.make_query("SELECT a.aid, a.atime, a.event, b.name, a.rtime, a.state, a.applicant_email, a.stime FROM approvals a LEFT JOIN users b ON a.reviewer_email=b.email LEFT JOIN users c ON a.applicant_email=c.email WHERE a.state in ('1', '2') AND c.seclock='#{@seclock}'")
      slim :'login/checkapplication', :locals => {:title => "查看审批情况"}
    end
  end

  # 办领导审批环节
  get '/authorize' do
    if(params[:lock].nil? or request.referer.nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      @seclock = params[:lock]
      # 如果这两个字段，表示是从该页面提交过来的进行批准的申请
      if(!params[:permit].nil? and !params[:aid].nil?)
        useremail = nil
        usertype = nil
        PgConnector.instance.make_query("SELECT email, type from users where seclock='#{@seclock}'").each_row do |row|
          useremail = row[0]
          usertype = row[1]
        end
        if(useremail.nil? or usertype!='1')
          slim :not_authorized, :locals => {:title => "出错啦！"}
        else
          id = params[:aid].to_i
          if(params[:permit] == "yes")
            PgConnector.instance.make_query("UPDATE approvals SET reviewer_email='#{useremail}', rtime='#{Time.now}', state='2' where aid='#{id}'")
          else
            PgConnector.instance.make_query("UPDATE approvals SET reviewer_email='#{useremail}', rtime='#{Time.now}', state='3' where aid='#{id}'")
          end
          @applications = PgConnector.instance.make_query("select a.aid 申请编号, b.name 申请人, c.name 所在处室, a.atime 申请时间, a.event 申请事项 from approvals a, users b, depts c where a.applicant_email=b.email and b.did=c.did and a.state='1'")
          slim :'login/authorize', :locals => {:title => "审核查询申请"}
        end
      else
        @applications = PgConnector.instance.make_query("select a.aid 申请编号, b.name 申请人, c.name 所在处室, a.atime 申请时间, a.event 申请事项 from approvals a, users b, depts c where a.applicant_email=b.email and b.did=c.did and a.state='1'")
        slim :'login/authorize', :locals => {:title => "审核查询申请"}
      end
    end
  end

  # 计算机处人员查看所有的查询记录
  get '/cs_view_queries' do
    if(params[:lock].nil? or request.referer.nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      @seclock = params[:lock]
      if(params[:startdate].nil?)
        slim :'login/cs_view_queries', :locals => {:title => "查看查询记录", :stylesheets => ["pickadate-default", "pickadate-default.date"], :scripts => ["picker", "picker.date", "picker.settings"]}
      else
        startdate = params[:startdate].to_s
        enddate = params[:enddate].to_s
        querier = params[:querier].to_s
        page = params[:page].to_i
        reccount = params[:reccount].nil? ? -1 : params[:reccount].to_i
        if(page*RecPerPage>reccount && reccount>0)
          page = reccount / RecPerPage
        end
        # 下面开始构建查询
        data_query = "from queries a left join users b on a.email=b.email left join approvals s on a.aid=s.aid left join users c on s.reviewer_email=c.email left join qtypes d on a.type=d.type where "
        data_query += "qtime >= timestamp '#{startdate} '" if(startdate.length>0)
        data_query += "and qtime <= timestamp '#{enddate} '" if(enddate.length>0)
        data_query += "and b.name='#{querier}' " if(querier.length>0)

        # 如果没有reccount，说明是新的查询，这时候需要统计记录数
        if(reccount == -1)
          count_query = "select count(*) "+data_query
          PgConnector.instance.make_query(count_query).each_row do |row|
            reccount = row[0].to_i
          end
        end
        data_query = "select a.qtime 查询时间, b.name 查询人, c.name 批准人, d.name 查询类别, a.keyword 查询关键字 " + data_query + " LIMIT #{RecPerPage} OFFSET #{page*RecPerPage}"
        @queries = PgConnector.instance.make_query(data_query)

        # 生成翻页按钮
        purl = ""
        nurl = ""
        if(page > 0)
          purl = "./cs_view_queries?page=#{page-1}&reccount=#{reccount}&startdate=#{startdate}&lock=#{@seclock}"
          purl += "&enddate=#{enddate}" if enddate.length>0
          purl += "&querier=#{querier}" if querier.length>0
        end
        if(reccount > (page+1)*RecPerPage)
          nurl = "./cs_view_queries?page=#{page+1}&reccount=#{reccount}&startdate=#{startdate}&lock=#{@seclock}"
          nurl += "&enddate=#{enddate}" if enddate.length>0
          nurl += "&querier=#{querier}" if querier.length>0
        end
        slim :'login/cs_view_queries', :locals => {:title => "查看查询记录", :stylesheets => ["pickadate-default", "pickadate-default.date"], :scripts => ["picker", "picker.date", "picker.settings"], :reccount => reccount, :purl => purl, :nurl => nurl }
      end
    end
  end

  # 办领导查看自己审批的查询记录
  get '/ld_view_queries' do
    if(params[:lock].nil? or request.referer.nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      @seclock = params[:lock]
      if(params[:startdate].nil?)
        slim :'login/ld_view_queries', :locals => {:title => "查看查询记录", :stylesheets => ["pickadate-default", "pickadate-default.date"], :scripts => ["picker", "picker.date", "picker.settings"]}
      else
        startdate = params[:startdate].to_s
        enddate = params[:enddate].to_s
        querier = params[:querier].to_s
        page = params[:page].to_i
        reccount = params[:reccount].nil? ? -1 : params[:reccount].to_i
        if(page*RecPerPage>reccount && reccount>0)
          page = reccount / RecPerPage
        end
        # 下面开始构建查询
        data_query = "from queries a left join users b on a.email=b.email left join approvals s on a.aid=s.aid left join users c on s.reviewer_email=c.email left join qtypes d on a.type=d.type where c.seclock='#{@seclock}' and "
        data_query += "qtime >= timestamp '#{startdate} '" if(startdate.length>0)
        data_query += "and qtime <= timestamp '#{enddate} '" if(enddate.length>0)
        data_query += "and b.name='#{querier}' " if(querier.length>0)
         # 如果没有reccount，说明是新的查询，这时候需要统计记录数
        if(reccount == -1)
          count_query = "select count(*) "+data_query
          PgConnector.instance.make_query(count_query).each_row do |row|
            reccount = row[0].to_i
          end
        end
        data_query = "select a.qtime 查询时间, b.name 查询人, c.name 批准人, d.name 查询类别, a.keyword 查询关键字 " + data_query + " LIMIT #{RecPerPage} OFFSET #{page*RecPerPage}"
        @queries = PgConnector.instance.make_query(data_query)

        # 生成翻页按钮
        purl = ""
        nurl = ""
        if(page > 0)
          purl = "./ld_view_queries?page=#{page-1}&reccount=#{reccount}&startdate=#{startdate}&lock=#{@seclock}"
          purl += "&enddate=#{enddate}" if enddate.length>0
          purl += "&querier=#{querier}" if querier.length>0
        end
        if(reccount > (page+1)*RecPerPage)
          nurl = "./ld_view_queries?page=#{page+1}&reccount=#{reccount}&startdate=#{startdate}&lock=#{@seclock}"
          nurl += "&enddate=#{enddate}" if enddate.length>0
          nurl += "&querier=#{querier}" if querier.length>0
        end
        slim :'login/ld_view_queries', :locals => {:title => "查看查询记录", :stylesheets => ["pickadate-default", "pickadate-default.date"], :scripts => ["picker", "picker.date", "picker.settings"], :reccount => reccount, :purl => purl, :nurl => nurl }
      end
    end
  end
end
