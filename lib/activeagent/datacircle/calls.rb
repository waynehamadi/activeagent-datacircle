# frozen_string_literal: true

module ActiveAgent
  module Datacircle
    # A plan holds about 90 keys (its terms of use, its aggregators...): a tool gives the ones that choose a plan,
    # the rest is on its page.
    PLAN_KEYS = %w[api rank provider plan score perThousand notFoundPerThousand billing pay currency units unit
                   strengths latencyMs page pricingPage docs].freeze

    # The four calls, one HTTPS GET each: what a tool gives, or Datacircle::Error.
    class << self
      # GET /apis
      def list_apis(query: nil, limit: nil)
        words = query.to_s.downcase.tr('-', ' ').split
        held = client.get('/apis').each_with_index.filter_map do |api, index|
          name = "#{api['api']} #{api['slug'].to_s.tr('-', ' ')}".downcase
          matched = words.count { |word| name.include?(word) }
          [-matched, index, api] if matched.positive? || words.empty?
        end
        found = held.sort_by { |matched, index, _| [matched, index] }
                    .map { |_, _, api| brief(api, %w[api slug plans providers best bestPage sheetPage]) }
        { 'total' => found.size, 'apis' => found.first(number(limit, 1, 200) || 20) }
      end

      # GET /apis/{slug}/best
      def best_plans(slug:, limit: nil)
        api = slugify(slug)
        raise Error, "Give an API's slug, like 'email-finder': datacircle_list_apis gives every slug" if api.empty?

        answer = client.get("/apis/#{api}/best", limit: number(limit, 1, 50))
        answer.merge('plans' => Array(answer['plans']).map { |plan| brief(plan) })
      end

      # GET /plans
      def search_plans(api: nil, query: nil, sort: nil, limit: nil, offset: nil)
        answer = search(api, query, sort, limit, offset)
        answer.merge('plans' => Array(answer['plans']).map { |plan| brief(plan) })
      rescue Error => e
        raise unless e.status == 400 && e.message.include?('api must be') && query.to_s.strip.empty?

        # A provider's name sent as the API: the plans whose provider or plan name holds it.
        answer = search(nil, api, sort, limit, offset)
        { 'note' => "No API is named #{api.to_s.inspect}: these are the plans whose provider or plan name holds it." }
          .merge(answer, 'plans' => Array(answer['plans']).map { |plan| brief(plan) })
      end

      # GET /providers/{slug}
      def provider(slug:)
        provider = slugify(slug)
        raise Error, "Give a provider's slug or name, like 'bright-data' or 'Bright Data'" if provider.empty?

        answer = client.get("/providers/#{provider}")
        apis = Array(answer['apis']).map do |entry|
          plans = Array(entry['plans'])
          brief(entry, %w[api slug rank bestPage]).merge('plans' => plans.size, 'best' => best(plans))
        end
        answer.merge('apis' => apis)
      end

      # A tool's answer: the call's, or the API's error as { 'error' => ... } for the agent to read.
      def answer
        yield
      rescue Error => e
        { 'error' => e.message }
      end

      private

      def client
        @client ||= Client.new
      end

      def search(api, query, sort, limit, offset)
        client.get('/plans', api: api, query: query, sort: (sort.to_s if %w[score provider price].include?(sort.to_s)),
                             limit: number(limit, 1, 50), offset: number(offset, 0, 1_000_000))
      end

      def brief(item, keys = PLAN_KEYS)
        keys.each_with_object({}) { |key, kept| kept[key] = item[key] unless item[key].nil? }
      end

      # A number the agent sent, within the API's range, or nil when it sent none.
      def number(value, low, high)
        return nil if value.nil? || value.to_s.strip.empty?

        Integer(value.to_s.strip, 10).clamp(low, high)
      rescue ArgumentError
        nil
      end

      # The API's rule for a slug: the name in lowercase letters and digits, the rest a hyphen.
      def slugify(value)
        value.to_s.strip.downcase.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '').gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
      end

      # A provider's best plan on an API: its lowest rank, a plan with no score having none.
      def best(plans)
        top = plans.min_by { |plan| plan['rank'].is_a?(Numeric) ? plan['rank'] : Float::INFINITY }
        top && brief(top, %w[plan score perThousand page])
      end
    end
  end
end
