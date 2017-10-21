require 'apartment/elevators/generic'

module Apartment
  module Elevators
    #   Provides a rack based tenant switching solution based on subdomains
    #   Assumes that tenant name should match subdomain
    #   Options:
    #      append_string (string)
    #         appends given string to the subdomain to create the tenant name
    #         e.g. my.domain.com  becomes my[string]
    #      prefix_string (string)
    #         prefixes a string to the subdomain to create the tenant name
    #         e.g.  my.domain.com becomes [string]domain
    class Fly < Generic
      def self.prefix_string
        @prefix_string ||= ""
      end
      def self.prefix_string=(arg)
        @prefix_string = arg
      end
      def self.append_string
        @append_string ||= ""
      end

      def self.append_string=(arg)
        @append_string = arg
      end

      def self.excluded_subdomains
        @excluded_subdomains ||= []
      end

      def self.excluded_subdomains=(arg)
        @excluded_subdomains = arg
      end

      def parse_tenant_name(request)
        # inhibit any subdomain tenant switching in test mode
        return nil if Rails.env == 'test'
        request_subdomain = subdomain(request.host)

        # If the domain acquired is set to be excluded, set the tenant to whatever is currently
        # next in line in the schema search path.
        tenant = if self.class.excluded_subdomains.include?(request_subdomain)
          nil
        else
          request_subdomain
        end
        tenant = self.apply_string_prefix(tenant)
        tenant = self.apply_string_append(tenant)
        tenant.presence
      end

      protected

      def apply_string_prefix(tenant)
        tenant = self.class.prefix_string + tenant if tenant.present? and self.class.prefix_string.present?
        tenant
      end
      def apply_string_append(tenant)
        tenant = tenant + self.class.append_string if tenant.present? and self.class.append_string.present?
        tenant
      end
      # *Almost* a direct ripoff of ActionDispatch::Request subdomain methods

      # Only care about the first subdomain for the database name
      def subdomain(host)
        subdomains(host).first
      end

      def subdomains(host)
        return [] unless named_host?(host)
        s = host.split('.')
        if s.count <= 1
          s
        else
          s[0..-(3)]
        end
      end

      def named_host?(host)
        !(host.nil? || /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.match(host))
      end
    end
  end
end
