# Ons Basisinkomen

## Installation

### Rubies and Gems

Obvious...

```bash
bundle install
```

### External credentials

Copy `.env.example` to `.env` and put your credentials in it.

```bash
cp .env.example .env
```

### Database

Migrate your database

```bash
bundle exec rake db:create
bundle exec rake db:migrate
````

When needed a testaccount, run seeds

```bash
bundle exec rake db:seed
````
