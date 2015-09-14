# coding: utf-8

require_relative './application_controller'
require_relative '../helpers/pg_connector'

class LoginController < ApplicationController
  get '/' do
    if params[:lock] != nil
      @seclock = params[:lock]
      result = PgConnector.instance.make_query("SELECT email, a.name, type, a.did, b.name cs FROM users a, depts b WHERE SECLOCK='#{@seclock}' and a.did=b.did")
      result.each_row {|row| (@useremail, @username, @usertype, @userdid, @userdept) = row}
      if @username.nil?
        slim :not_authorized, :locals => {:title => "出错啦！"}
      else
        if @usertype == "3"       # 普通人员
          slim :'login/common_login', :locals => {:title => "查询审批"}
        elsif @usertype == "2"    # 计算机处人员
          slim :'login/cs_login', :locals => {:title => "计算机审计处人员登录"}
        else
          slim :'login/ld_login', :locals => {:title => "办领导登录"}
        end
      end
    else
      slim :not_authorized, :locals => {:title => "出错啦！"}
    end
  end
end
