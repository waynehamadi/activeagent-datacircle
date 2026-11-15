# Datacircle tools for Active Agent

Find the best GTM APIs. We benchmark all the GTM APIs and we put the results on our website: https://datacircle.dev

This gem gives your [Active Agent](https://github.com/activeagents/activeagent) agents four tools that call Datacircle's open API, https://api.datacircle.dev/v1. You need no key and no account.

| Tool | What the tool gives | Call |
| --- | --- | --- |
| `datacircle_list_apis` | Every GTM API on Datacircle, with the API's slug, number of plans, number of providers and best plan | `GET /apis` |
| `datacircle_best_plans` | One API's plans, sorted by score out of 100, best first. Each plan comes with a rank and a price per 1,000 calls | `GET /apis/{slug}/best` |
| `datacircle_search_plans` | Plans that match a provider or plan name. Search all APIs or one API. Sort by score, provider or price | `GET /plans` |
| `datacircle_provider` | The APIs a provider sells, and the provider's rank on each API | `GET /providers/{slug}` |

## Install

```bash
bundle add activeagent-datacircle
```

The gem needs Active Agent 1.9 or later and Ruby 3.1 or later.

## Use the tools

Include the module in an agent. Pass `datacircle_tools` to `prompt`. The agent answers each tool call with the method of the same name.

```ruby
class PlanAgent < ApplicationAgent
  include ActiveAgent::Datacircle

  def ask
    prompt(message: params[:question], tools: datacircle_tools)
  end
end

PlanAgent.with(question: "Which email finder API is best for under $5 per 1,000?").ask.generate_now
```

To give an action fewer tools, pass their names to `datacircle_tools`:

```ruby
prompt(message: params[:question], tools: datacircle_tools(:best_plans, :search_plans))
```

`ActiveAgent::Datacircle::TOOLS` holds the four tool definitions in Active Agent's common format.

You can call a tool yourself:

```ruby
PlanAgent.new.datacircle_best_plans(slug: "email-finder", limit: 3)
# => {"api" => "Employee email", "slug" => "email-finder", ..., "plans" => [{"api" => "Employee email", "rank" => 1, "provider" => "Emelia", ...}, ...]}
```

Each plan comes with a rank, provider, plan, score, price per 1,000 (`perThousand`, in dollars) and a page on datacircle.dev. That page lists every field. The tool gives `{"error" => ...}` with the API's words when the API has no data, for example for an unknown slug. The agent reads the error and can call the tool again. Module calls like `ActiveAgent::Datacircle.best_plans(slug: "email-finder")` raise `ActiveAgent::Datacircle::Error` when the API has no data.

## Network

Each tool call makes one HTTPS GET request to https://api.datacircle.dev/v1. A plan search makes a second request when the agent names a provider instead of an API. A request holds only the tool's own arguments: no key, no config, nothing from your prompts. The API takes up to 60 calls a minute from one IP address. The tool waits once, for a minute at most, when the API asks the tool to wait. The gem depends only on Active Agent and stores nothing.

## Links

- Datacircle: https://datacircle.dev
- The API: https://datacircle.dev/api
- The API's spec: https://api.datacircle.dev/v1/openapi.json
- What each key means: https://datacircle.dev/fields

MIT license.
