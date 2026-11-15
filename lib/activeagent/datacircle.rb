# frozen_string_literal: true

require 'active_agent'
require_relative 'datacircle/version'
require_relative 'datacircle/client'
require_relative 'datacircle/tools'
require_relative 'datacircle/calls'

module ActiveAgent
  # Four Active Agent tools on Datacircle's open API (https://api.datacircle.dev/v1), with no key. An agent that
  # includes this module answers them with its methods of the same names:
  #
  #   class PlanAgent < ApplicationAgent
  #     include ActiveAgent::Datacircle
  #
  #     def ask(question:)
  #       prompt(message: question, tools: datacircle_tools)
  #     end
  #   end
  module Datacircle
    # The tools' definitions, all four or those named (:best_plans or 'datacircle_best_plans'), for prompt(tools: ...).
    def self.tools(*names)
      wanted = names.flatten.map { |name| name.to_s.delete_prefix('datacircle_') }
      unknown = wanted - TOOLS.map { |tool| tool[:name].delete_prefix('datacircle_') }
      raise ArgumentError, "No Datacircle tool is named #{unknown.join(', ')}" if unknown.any?

      TOOLS.select { |tool| wanted.empty? || wanted.include?(tool[:name].delete_prefix('datacircle_')) }.deep_dup
    end

    # GET /apis: every API on the sheet, those whose name holds query's words first.
    def datacircle_list_apis(query: nil, limit: nil, **)
      Datacircle.answer { Datacircle.list_apis(query: query, limit: limit) }
    end

    # GET /apis/{slug}/best: one API's plans, best first.
    def datacircle_best_plans(slug: nil, limit: nil, **)
      Datacircle.answer { Datacircle.best_plans(slug: slug, limit: limit) }
    end

    # GET /plans: the plans whose provider or plan name holds query, on every API or on one.
    def datacircle_search_plans(api: nil, query: nil, sort: nil, limit: nil, offset: nil, **)
      Datacircle.answer { Datacircle.search_plans(api: api, query: query, sort: sort, limit: limit, offset: offset) }
    end

    # GET /providers/{slug}: one provider's rank on each API it sells.
    def datacircle_provider(slug: nil, **)
      Datacircle.answer { Datacircle.provider(slug: slug) }
    end

    private

    def datacircle_tools(*names)
      Datacircle.tools(*names)
    end
  end
end
