# Кто хочет стать миллионером?!

Игра для детей от 12 до 159 лет.

Учебное приложение курса по Ruby on Rails от «Хорошего программиста».

В учебных целях выполнено:

- Тестирование с помощью библиотеки `Rspec`;
- Создание фабрик для тестов с помощью библиотеки `FactoryBot`;
- Тестирование моделей;
- Тестирование контроллеров;
- Тестирование представлений с помощью библиотеки `Capybara`.

Требуемая версия Ruby и Rails:

```
ruby >= 2.5.1
rails ~> 4.2.6
```

Для запуска выполните в терминале следующие шаги:

1. Установите `Bundler`, если он ещё не установлен:

```
gem install bundler
```

2. Склонируйте репозиторий:

```
git clone https://github.com/yurinds/millionaire.git

# переход в папку с приложением
cd millionaire
```

3. Установите все зависимости:

```
bundle install
```

4. Выполните миграции БД:

```
bundle exec rails db:migrate
```

5. Выполните тесты:

```
bundle exec rspec
```

6. Запустите сервер приложения:

```
bundle exec rails s
```

7. Откройте в браузере:

```
http://localhost:3000
```

© http://goodprogrammer.ru
