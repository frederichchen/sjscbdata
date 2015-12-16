# coding: utf-8
require 'base64'
require 'time'
require_relative './application_controller'
require_relative '../helpers/pg_connector'

class PortalController < ApplicationController
  get '/' do
    if(params[:lock].nil? or request.referer.nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      (useremail, aid, accesstime) = Base64.urlsafe_decode64(params[:lock]).split("|")
      if(useremail.nil? or aid.nil? or accesstime.nil?)
        slim :not_authorized, :locals => {:title => "出错啦！"}
      else
        accesstime = Time.parse(accesstime)
        result = PgConnector.instance.make_query("SELECT name FROM users WHERE email='#{useremail}'")
        @username = nil
        result.each_row { |row| @username = row[0] }
        if @username.nil?
          slim :not_authorized, :locals => {:title => "出错啦！"}
        elsif accesstime+3600 < Time.now
          slim :timeout, :locals => {:title => "授权时间已过！"}
        else
          session['email'] = useremail
          session['atime'] = accesstime
          session['aid'] = aid
          # 非办领导或计算机处人员访问，如果授权时间已到，需要把approvals表对应的记录的状态改为已“0-已查询”
          if(aid.to_i > 0)
            PgConnector.instance.make_query("UPDATE approvals SET stime= CASE WHEN stime IS NULL THEN '#{Time.now}' ELSE stime END WHERE aid=#{aid}")
          end
          slim :'portal/index', :locals => {:title => "欢迎使用成都办数据中心查询系统", :stylesheets => ["portal"] }
        end
      end
    end
  end

  get '/about' do
    if(session['email'].nil? or session['atime'].nil? or session['aid'].nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      slim :'portal/about', :locals => {:title => "关于本查询系统"}
    end
  end

  get '/psearch' do
    if(session['email'].nil? or session['atime'].nil? or session['aid'].nil? or request.referer.nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      slim :'portal/psearch', :locals => {:title => "查询个人信息", :stylesheets => ["bootstrap-select.min"], :scripts => ["bootstrap-select.min", "select.settings"]}
    end
  end

  get '/esearch' do
    if(session['email'].nil? or session['atime'].nil? or session['aid'].nil? or request.referer.nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      slim :'portal/esearch', :locals => {:title => "查询企业信息", :stylesheets => ["bootstrap-select.min"], :scripts => ["bootstrap-select.min", "select.settings"]}
    end
  end

  get '/cgsearch' do
    if(session['email'].nil? or session['atime'].nil? or session['aid'].nil? or request.referer.nil?)
      slim :not_authorized, :locals => {:title => "出错啦！"}
    else
      slim :'portal/cgsearch', :locals => {:title => "查询财政供养信息", :stylesheets => ["bootstrap-select.min"], :scripts => ["bootstrap-select.min", "cgselect.settings"]}
    end
  end
end
