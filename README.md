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

Для правильной работы с `Rails console` необходимо пользоваться:

```bash
  TENANT=tenant rails gc # по умолчанию TENANT = default
```

Проверить, что в каком вы тенанте можно с помощью

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
