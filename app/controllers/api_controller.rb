class ApiController < ActionController::API
  include ApiGuard
  # before_action Proc.new { |controller| guard_all!(scope: params[:scope]) }
  before_action :guard_all!

  def secret_1
    respond_to json: { :secret1 => "Hi, alan@techbang.com.tw" }.to_json
  end

  def secret_2
    respond_to json: { :secret2 => "only smart guys can see this ;)" }.to_json
  end
end
