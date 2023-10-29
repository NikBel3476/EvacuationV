# EvacuationV

**EvacuationV** -- программа моделирования движения людей в здании.

Результатом работы программы является время освобождения здания (длительность эвакуации).

## Необходимые инструменты
#### [v lang](https://vlang.io)

## Запуск
1. Скачать репозиторий`git clone https://github.com/NikBel3476/EvacuationV`
2. Перейти в директорию `cd EvacuationV`
3. Запуск `v run . cfg scenario.json`

# Сборка исполняемого файла
v . - debug режим
v -prod . - release режим

# Конфигурация
Настройки моделируемого сценария задаются в файле-сценарии. Он состоит из нескольких секций:

```
{
  "bim": [],                 -- список цифровых моделей зданий,
  "logger_configure": "",    -- путь к файлу с настроками логгирования
  "distribution": {},        -- настройки распределения людей в здании
  "transits": {},            -- настройки ширины проемов в здании
  "modeling": {}             -- настройки модели движения людского потока в здании
}
```

Примечание: при использовании относительных путей в списке цифровых моделей зданий необходимо учитывать путь от места вызова исполняемого файла

### distribution

Через блок `distribution` можно задать выбрать тип (`type`) распределения людей в здании:

```
uniform   -- равномерное распределение людей в здании с заданной плотностью (density)
from_bim  -- распеделение, которое задано в пространственно-информационной модели здания
```

В поле `density` указывается плотность начального количества людей, чел./м^2

В блоке `special` можно указать специальные настройки для одного или группы областей здания.
Этот блок обрабатывается всегда.

```
"distribution": {
    "type":"uniform",
    "density": 0.1,
    "special": [
        {
            "uuid": [
            "87c49613-44a7-4f3f-82e0-fb4a9ca2f46d"
            ],
            "density": 1.0,
            "_comment": "The uuid is Room_1 by three_zone_three_transit"
        }
    ]
  }
```

### transits

### modeling
