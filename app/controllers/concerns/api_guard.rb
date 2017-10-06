require 'doorkeeper/orm/active_record/access_token'

module ApiGuard
  extend ActiveSupport::Concern

  ERROR_CLASSES = [
    MissingTokenError,
    TokenNotFoundError,
    ExpiredError,
    RevokedError,
    InsufficientScopeError
  ]

  included do
    # OAuth2 Resource Server Authentication
    use Rack::OAuth2::Server::Resource::Bearer, 'The API' do |request|
      # The authenticator only fetches the raw token string

      # Must yield access token to store it in the env
      request.access_token
    end

    rescue_from *ERROR_CLASSES do |exception|
      oauth2_bearer_token_error_handler(exception)
    end
  end

  module ClassMethods

  end

  def oauth2_bearer_token_error_handler(exception)
    response = case exception
      when MissingTokenError
        Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new

      when TokenNotFoundError
        Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
          :invalid_token,
          "Bad Access Token.")
      # etc. etc.
      end

    response.finish
  end

  def guard!(scopes: [])
    token_string = get_token_string()
    if token_string.blank?
      raise ::MissingTokenError

    elsif (access_token = find_access_token(token_string)).nil?
      raise ::TokenNotFoundError

    else
      case validate_access_token(access_token, scopes)
      when Oauth2::AccessTokenValidationService::INSUFFICIENT_SCOPE
        raise InsufficientScopeError.new(scopes)

      when Oauth2::AccessTokenValidationService::EXPIRED
        raise ExpiredError

      when Oauth2::AccessTokenValidationService::REVOKED
        raise RevokedError

      when Oauth2::AccessTokenValidationService::VALID
        @current_user = User.find(access_token.resource_owner_id)

      end
    end
  end

  def guard_all!(scopes: [])
    guard! scopes: scopes
  end

  private

  def get_token_string
    # The token was stored after the authenticator was invoked.
    # It could be nil. The authenticator does not check its existence.
    request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
  end

  def find_access_token(token_string)
    Doorkeeper::AccessToken.authenticate(token_string)
  end

  def validate_access_token(access_token, scopes)
    OAuth2::AccessTokenValidationService.validate(access_token, scopes: scopes)
  end
end
