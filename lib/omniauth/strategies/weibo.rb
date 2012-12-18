require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Weibo < OmniAuth::Strategies::OAuth2
      option :client_options, {
        :site           => "https://api.weibo.com",
        :authorize_url  => "/oauth2/authorize",
        :token_url      => "/oauth2/access_token"
      }
      
      option :token_params, {
        :parse          => :json
      }
      
      uid { raw_info['id'].to_s }

      info do
        {
          :nickname     => raw_info['screen_name'],
          :name         => raw_info['name'],
          :location     => raw_info['location'],
          :image        => raw_info['profile_image_url'],
          :description  => raw_info['description'],
          :urls => {
            'Blog'      => raw_info['url'],
            'Weibo'     => raw_info['domain'].present?? "http://weibo.com/#{raw_info['domain']}" : "http://weibo.com/u/#{raw_info['id']}",
          }
        }
      end

      extra do
        { :raw_info => raw_info }
      end

      def raw_info
        uid = access_token[:uid] || access_token["uid"]
        @token_info ||= access_token.params.merge("token" => access_token.token)
        @raw_info ||= {"token_info" => @token_info}.merge(access_token.get("/2/users/show.json", :params => {:uid => uid}).parsed)
      end

      def authorize_params
        super.tap do |params|
          %w[display with_offical_account state].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]

              # to support omniauth-oauth2's auto csrf protection
              session['omniauth.state'] = params[:state] if v == 'state'
            end
          end
        end
      end
      
      protected
        def build_access_token
          super.tap{ |access_token| access_token.options.merge!(:mode => :query, :param_name => :access_token) }
        end
      
    end
    
  end
end

OmniAuth.config.add_camelization "weibo", "Weibo"