require 'rubygems'
require 'active_support'
require 'action_controller/request'
require 'oauth/request_proxy/base'
require 'uri'

module OAuth::RequestProxy
  class ActionControllerRequest < OAuth::RequestProxy::Base
    proxies ActionController::AbstractRequest

    def method
      request.method.to_s.upcase
    end

    def uri
      uri = URI.parse(request.protocol + request.host + request.port_string + request.path)
      uri.query = nil
      uri.to_s
    end

    def parameters
      if options[:clobber_request]
        options[:parameters] || {}
      else
        params = request_params.merge(query_params).merge(header_params)
        params.stringify_keys! if params.respond_to?(:stringify_keys!)
        params.merge(options[:parameters] || {})
      end
    end
    
    # Override from OAuth::RequestProxy::Base to avoid roundtrip
    # conversion to Hash or Array and thus preserve the original
    # parameter names
    def parameters_for_signature
      params = []
      params << options[:parameters].to_query if options[:parameters]

      unless options[:clobber_request]
        params << header_params.to_query
        params << CGI.unescape(request.query_string) unless request.query_string.blank?
        if request.content_type == Mime::Type.lookup("application/x-www-form-urlencoded")
          params << CGI.unescape(request.raw_post)
        end
      end
      
      params.
        join('&').split('&').
        reject { |kv| kv =~ /^oauth_signature=.*/}.
        reject(&:blank?).
        map { |p| p.split('=') }
    end

    protected

    def query_params
      request.query_parameters
    end

    def request_params
      request.request_parameters
    end

  end
end
