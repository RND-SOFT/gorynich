# Gorynich

<div align="center">

[![Gem Version](https://badge.fury.io/rb/gorynich.svg)](https://rubygems.org/gems/gorynich)
[![Gem](https://img.shields.io/gem/dt/gorynich.svg)](https://rubygems.org/gems/gorynich/versions)
[![YARD](https://badgen.net/badge/YARD/doc/blue)](http://www.rubydoc.info/gems/gorynich)


[![quality](https://lysander.rnds.pro/api/v1/badges/gorynich_quality.svg)](https://lysander.rnds.pro/api/v1/badges/gorynich_quality.html)
[![outdated](https://lysander.rnds.pro/api/v1/badges/gorynich_outdated.svg)](https://lysander.rnds.pro/api/v1/badges/gorynich_outdated.html)
[![vulnerable](https://lysander.rnds.pro/api/v1/badges/gorynich_vulnerable.svg)](https://lysander.rnds.pro/api/v1/badges/gorynich_vulnerable.html)

</div>

Gorynich это гем для реализации [мультитенантности](https://ru.wikipedia.org/wiki/Мультиарендность) (мультиарендности) в Ruby on Rails приложении. Позволяет обеспечить строгую изоляцию данных в нескольких СУБД, поддерживаемых в ActiveRecord.

---

`Gorynich` provides tools for creating [Multitenancy](https://en.wikipedia.org/wiki/Multitenancy) Ruby on Rails application. If you need to have strong data segregation and isolated DBMS's with diffrent providers (supported by ActiveRecord) and credentials, `Gorynich` can help.

Возможности / Features

- Прозрачное переключение БД на основании доменов / Transparent domain based DBMS switching
- Интеграция с / Integrations:
  - ActiveRecord
  - ActionCable
  - ActiveJob
  - DelayedJob
- Получение параметров из [Consul KV](https://developer.hashicorp.com/consul/docs/dynamic-app-config/kv) / Stoting configuration in [Consul KV](https://developer.hashicorp.com/consul/docs/dynamic-app-config/kv)
- Получение параметров из файла / Storing configuration in file
- Разеделение секретов / Secret storing and isolation
- Обновление конфигурации "на лету" / update configuration "on the fly"
- Статическая генерация `database.yml` / Static `database.yml` generation


## Начало работы / Getting started

```sh
gem install gorynich
```

При установке `Gorynich` через bundler добавте следующую строку в `Gemfile`:

---

If you'd rather install `Gorynichr` using bundler, add a line for it in your `Gemfile`:

```sh
gem 'gorynich'
```

Затем выполнить / Then run:

```sh
bundle install # для установки гема / gem installation

rails generate gorynich:install # для добавления шаблонов конфигурации / install configutation templates 
```

## Что такое тенант? / What tenant is?

Тенант в данном случае это активное подключение к СУБД, а также доступный в любом месте объект `Gorynich::Current`, в котором находятся параметры текущенго тенанта:

```ruby
Gorynich::Current.tap do |t|
  t.tenant   # tenant_name
  t.uri      # https://app.domain.org/posts/5
  t.host     # app.domain.org
  t.secrets  # { key1 => value1, key2 => value2}
  t.database # { adapter => postgresql, host => localhost, port => 5432, username => xxx, password => xxx }
end
```

## Использование / Usage

### Настройка источника данных / Configuration source 

Для использования необходимо в файле `config/application.rb` добавить источник данных. Сейчас доступны 2 источника:

---

Now you need to select configuration source in `config/application.rb`. Yuo can choose from 2 source types now:


```ruby
Gorynich::Fetchers::File.new(file_path: [FILE_PATH]) # из файла / from file

Gorynich::Fetchers::Consul.new(storage: [CONSUL_KEY], **options) # из консула / from consul (options - from Dimplomat gem https://github.com/WeAreFarmGeek/diplomat)
```

Пример / Example:

```ruby
# из одного / from single sourc
Gorynich.configuration.fetcher = Gorynich::Fetchers::File.new(file_path: Rails.root.join('config', 'gorynich_config.yml'))

# из нескольких (данные берутся от первого успешного fetcher)
# from multiple sources - first succesful source is used
Gorynich.configuration.fetcher  = [
  Gorynich::Fetchers::Consul.new(storage: 'gorynich_project/config'),
  Gorynich::Fetchers::File.new(file_path: Rails.root.join('config', 'gorynich_config.yml'))
]
```

### Настройка интеграций ("голов") / Integration "Heads"

`Gorynich` настраивается в обычных инициалайзерах / `Gorynich` configured in initializer:

```ruby
# config/initializers/gorynich.rb

Gorynich.configure do |config|
  # config cache of gorynich
  config.cache = Rails.cache

  # config cache namespace
  config.namespace = ENV.fetch('YOUR_NAMESPACE_ENV', 'your_namespace')

  # config how long your source cache will be alive in seconds
  config.cache_expiration = 'your_value'

  # Custom handler for swithing tenants in gorynich rack middleware
  config.rack_env_handler =
    lambda do |env|
      host = env['SERVER_NAME']
      tenant = Gorynich.instance.tenant_by_host(host)
      uri = Gorynich.instance.uri_by_host(host, tenant)

      Sentry.set_tags(tenant: tenant) if Sentry.get_current_scope.present?

      [tenant, { host: host, uri: uri }]
    end
end

# Add cable head
ActiveSupport.on_load(:action_cable_connection) do
  include Gorynich::Head::ActionCable::Connection
end

ActiveSupport.on_load(:action_cable_channel) do
  prepend Gorynich::Head::ActionCable::Channel
end

# Add active job head
ActiveSupport.on_load(:active_job) do
  include Gorynich::Head::ActiveJob
end
```

### Rake Tasks

Запуск `Rails console` внутри тенанта / Run `rails console` inside tenant:

```bash
TENANT=tenant rails gc # default tenant name id  'default'
```

Для создания статичного файла `database.yml` из источника данных (Fetcher), используйте:

--- 

For static `database.yml` generation from configured source (Fetcher) use:

```bash
rails gc:db:prepare
```

### Настройка конфигурации БД / Database configuration

Первый, самый простой способ работы, подходящий для локальной разработки это статическая генерация `database.yml`.

--- 

First and most simple using of Gorynich handy for local development is static `database.yml` generation.

1. запуск rake-задачи / runing rake task:

```bash
rails gc:db:prepare
```

Второй вариант это создание конфигурации `database.yml` при старте Rails приложения - данные буду прочитаны из настроенного источника. В этом случае конфигурация СУБД может изменяться только при перезапуске приложения, но остальные настройки, такие как привязка тенантов к доменам и secrets будут подхватываться "на лету" непосредственно во время работы приложения. Rake-задачи `db:create`, `db:migrate` работают для всех тенантов на момент запуска. 

---

Second option is dynamic `database.yml` creation while starting Rails application. Configuration will be readed from selected source. In this case database configuration can change only when application restarts, bout other configuration such a domain to tenant binding and application secrets wil be updated "on the fly" while application running. Rake tasks `db:create` and `db:migrate` works as expected for all tenant in order.

>> ВНИМАНИЕ! `db:rollback` не работает в мультитенантном режиме.

>> WARNING!  `db:rollback` is not working in multitenancy mode.

2. В `database.yml` прописать следующее / In `database.yml` set:

```yaml
# config/database.yml
<%= Gorynich.instance.database_config %>
```

Если вам нужны дополнительные БД, не являющимися тенантами, например, общая БД, то в `database.yml` можно дописать всё необходимое как о обычном Rails приложении:

---

If you need additional DB, not for tenants Ex. generic database you can configure it in `database.yml` like in regular Rails application:

3. Если вам нужны дополнительные БД, не являющимися тенантами, например, общая БД, то в `database.yml` нужно прописать следующее:

```yaml
# config/database.yml
<%= Gorynich.instance.database_config('development') %>

your_database:
  <<: *configs_for_your_database

<%= Gorynich.instance.database_config('test') %>
your_database:
  <<: *configs_for_your_database

<%= Gorynich.instance.database_config('production') %>
your_database:
  <<: *configs_for_your_database
```

### В коде / Inside code
Проверить в каком вы тенанте можно с помощью / Check in which tenant you are:

```ruby
Gorynich::Current.tenant
```

Переключение тенантов работает автоматичеки и внутри Rails приложения не нужни предпринимать никаких дополнительных действий - вы всегда подключены к той базе даанных к которой приязан домен текущего запроса. Но если необходимо явно выполнить действия в контексте конкретного тената это можно сделать:

---

Switching tenants is automatic and no additional steps need to be taken inside a Rails applicationSwitching tenants is automatic and no additional steps need to be taken inside a Rails application - you always connected to database associated with currently procesed request. But if you want take action inside specific tenant context you can use:

```ruby
  # для выполнения в конкретном тенанте / run block inside specific tenant
  Gorynich.with('tenant_name') do
    # your code
  end

  # для выполнения в каждом тенанте / run block inside each tenant
  Gorynich.with_each_tenant do |tenant|
    # your code
  end
```

## Как это работает / How it works

Перед обработкой запроса с помощью [Gorynich::Rack::RackMiddleware](./lib/gorynich/head/rack_middleware.rb) соединение Active Record переключается на указанную БД, а с помощью [ActiveSupport::CurrentAttributes](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html) в любом месте приложения становятся доступны дополнительные параметры через обращение к `Gorynich::Current`. ActionCable, ActiveJob и другие "головы" используют настройки из `Gorynich::Current` для сохранения контекста и дальнейшего исполнения.

--- 

Before request processing [Gorynich::Rack::RackMiddleware](./lib/gorynich/head/rack_middleware.rb) ActiveRecord connection switching to apropriate database. Additional tenant properties available in any part of application through [ActiveSupport::CurrentAttributes](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html) as  `Gorynich::Current` instance. ActionCable, ActiveJob and other "heads" also uses `Gorynich::Current` to store context and evaluate it later.


## Примеры дополнительных интеграций / Additional integration examples

### Redis / Rails.cache

```ruby
#config/environments/production.rb

config.cache_store = :redis_cache_store, {
  url:                ENV.fetch('REDIS_URL', nil),
  expires_in:         90.minutes,
  connect_timeout:    3,
  reconnect_attempts: 3,
  namespace:          -> { "#{Gorynich.configuration.namespace}#{Gorynich::Current.tenant}" }
}
```

### Sentry

```ruby
#config/initializers/gorynich.rb

Gorynich.configure do |config|
  config.rack_env_handler =
    lambda do |env|
      host = env['SERVER_NAME']
      tenant = Gorynich.instance.tenant_by_host(host)
      uri = Gorynich.instance.uri_by_host(host, tenant)

      Sentry.set_tags(tenant: tenant) if Sentry.get_current_scope.present?

      [tenant, { host: host, uri: uri }]
    end
end
```

### Telegram

```ruby
#config/environments/production.rb

config.telegram_updates_controller.session_store = :redis_cache_store, {
  url:        ENV.fetch('REDIS_URL', nil),
  expires_in: 90.minutes,
  namespace:  -> { "#{Gorynich.configuration.namespace}#{Gorynich::Current.tenant}" }
}
```

### Telegram Bot

```ruby
#lib/gorynich/head/telegram.rb

module Gorynich
  module Head
    module Telegram
      class Middleware
        attr_reader :controller

        def initialize(controller)
          @controller = controller
        end

        def call(env)
          request = ActionDispatch::Request.new(env)
          token = request.params['token']
          if token.present?
            update = request.request_parameters
            controller.dispatch(nil, update)
            [200, {}, ['']]
          else
            [404, {}, ['']]
          end
        end

        def inspect
          "#<#{self.class.name}(#{controller.try!(:name)})>"
        end
      end
    end
  end
end

#config/initializers/telegram.rb
require 'gorynich/head/telegram'

Telegram::Bot::UpdatesPoller.include(Gorynich::Head::Telegram)
```

### Shirine 

```ruby
#lib/shrine/plugins/tenant_location.rb

class Shrine
  module Plugins
    module TenantLocation
      module InstanceMethods
        def generate_location(io, **options)
          "#{Gorynich::Current.tenant}/#{super}"
        end
      end
    end

    register_plugin(:tenant_location, TenantLocation)
  end
end

#config/initializers/shrine.rb

Shrine.plugin :tenant_location
```

## Лицензия / License

[MIT](./LICENSE)