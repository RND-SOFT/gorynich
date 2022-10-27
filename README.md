# Gorynich
Гем для переключения конфигурации мультитенантного приложения

## Установка
Добавить Gemfile:

```ruby
  source 'https://library.rnds.pro/repository/internal' do
    gem 'gorynich'
  end
```

Выполнить:

```bash
  bundle install # для установки гема

  rails g gorynich:install # для добавления шаблонов конфигурации
```

## Использование

### Настройка источника данных

Для использования необходимо в файле `config/initializer/gorynich.rb` добавить источник данных. Сейчас доступны 2 источника:

```ruby
  Gorynich::Fetchers::File.new(file_path: [FILE_PATH]) # из файла

  Gorynich::Fetchers::Consul.new(storage: [CONSUL_KEY], **options) # из консула (options - параметры гема https://github.com/WeAreFarmGeek/diplomat)
```

Пример:

```ruby
  # из одного
  Gorynich.configure do |config|
    config.fetcher = Gorynich::Fetchers::File.new(file_path: Rails.root.join('config', 'gorynich_config.yml'))
  end

  # из нескольких (данные берутся от первого успешного fetcher)
  Gorynich.configure do |config|
    config.fetcher = [
      Gorynich::Fetchers::Consul.new(storage: 'gorynich_project/config'),
      Gorynich::Fetchers::File.new(file_path: Rails.root.join('config', 'gorynich_config.yml'))
    ]
  end
```

### Tasks

Для правильной работы с `Rails console` необходимо пользоваться:

```bash
  TENANT=tenant rails gc # по умолчанию TENANT = default
```

Для создания статичного файла `database.yml` из источника данных (Fetcher), используйте:

```bash
  rails gc:db:prepare
```

### Настройка конфигурации БД

Работать с `database.yml` можно 3-мя способами:

1. Создать статичный файл `database.yml`:

```bash
  rails gc:db:prepare
```

`database.yml` будет заполнен конфигурациями тенантов из источника данных (Fetcher)

2. В `database.yml` прописать следующее

  ```yaml
  <%= Gorynich.instance.database_config %>
  ```

При такой конфигурации динамически будут создаваться конфигурации тенантов. Но при этом не будет работать таска `rollback` (`db:create` `db:migrate` работают).

3. Если вам нужны дополнительные БД, не являющимися тенантами, например, общая БД, то в `database.yml` нужно прописать следующее:

 ```yaml
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

Как и во 2-ом случае, будет динамически создаваться конфигурация тенантов и не работать таска `rollback`.

### В коде
Проверить в каком вы тенанте можно с помощью

```ruby
  Gorynich::Current.tenant
```

Для переключения между тенантами используйте:

```ruby
  # для выполнения в конкретном тенанте
  Gorynich.with([TENANT]) do
    # your code
  end

  # для выполнения в каждом тенанте
  Gorynich.with_each_tenant do |tenant|
    # your code
  end
```
