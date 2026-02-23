# Social Kitchen Dashboard (MVP)

Rails 7.1 multi-tenant platform for social kitchen operations:

- Public portal (tenants + menu of the day)
- Tenant dashboard (inventory, scan, menu generation)
- Global admin panel (tenants, users, metrics, audit logs)
- OpenFoodFacts integration (barcode product normalization)
- OpenAI integration (automatic menu generation with fallback)

## Stack

- Ruby 3.3.5
- Rails 7.1
- PostgreSQL
- Devise (auth)
- Pundit (authorization)
- Sidekiq + Redis (background jobs)
- Turbo/Stimulus (SSR + progressive UX)

## Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
```

Run web:

```bash
bin/rails server
```

Run worker:

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

## Environment variables

- `OPENAI_API_KEY` (required for AI generation)
- `OPENAI_MODEL` (optional, default: `gpt-4o-mini`)
- `REDIS_URL` (optional in local, required in cloud worker)
- `APP_HOST` (production URL for mailer links)

Using `.env` (recommended in local):

```bash
cp .env.example .env
# Edit .env with your real key
```

Alternative with exported vars:

```bash
export OPENAI_API_KEY="sk-..."
export OPENAI_MODEL="gpt-4o-mini"
```

Never commit API keys to source code, seeds, or repository config.

## Demo credentials

Loaded by `db:seed`:

- Admin: `admin@socialkitchen.local` / `ChangeMe123!`
- Ops admin: `ops-admin@socialkitchen.local` / `ChangeMe123!`
- Manager: `manager+comedor-central@socialkitchen.local` / `ChangeMe123!`
- Staff: `staff-a+comedor-central@socialkitchen.local` / `ChangeMe123!`

## Main routes

- Public: `/`
- Sign in: `/users/sign_in`
- Tenant dashboard: `/tenant/dashboard`
- Admin metrics: `/admin/metrics`
- API base: `/api/v1`

## Heroku

`Procfile` includes:

- `web`: Puma
- `worker`: Sidekiq

Provision add-ons:

- Heroku Postgres
- Heroku Redis
