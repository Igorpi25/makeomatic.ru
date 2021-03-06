title: "Angular.JS: основы создания директив"
subtitle: концепции и практическое применение
date: 2013-08-17
author: Дмитрий Горбунов
gravatarMail: atskiisotona@gmail.com
tags: [AngularJS]
---

## Подготовка

### Модульная структура

Как я уже писал ранее, AngularJS является достаточно структурированной библиотекой. Практически каждый элемент функциональности выделен в свой модуль: $http, $resource, $route, $location и так далее. Фактически сама библиотека сконцентрирована в модуле Core. Подключать его не нужно (как и многие другие модули, вроде $http), поскольку он входит в основу библиотеки.

Начиная с версии 1.1.6 модуль $route нужно подключать отдельно, поскольку было принято решение исключить его из ядра и впоследствии объединить с модулем ui.state от команды AngularUI.

### Расширение функциональности

Следует заметить, что вызов `angular.module` может работать по-разному в зависимости от переданных ему параметров. Если переданное первым параметром имя модуля соответствует уже существующему модулю, то вызов вернёт ссылку *на этот модуль*, если же такого модуля нет, то он предварительно *будет создан*.

Это позволяет держать код в разных файлах и не заботиться о последовательности их подключения/склейки. Достаточно лишь в начале каждого файла написать

```javascript
var myModule = angular.module("MyModule")
```

<!-- more -->

Разумеется, можно подключать и зависимости, их наличие не влияет на работу функции `angular.module`.

### Настройка модуля

Каждый модуль ведёт себя как полноценный элемент приложения и сам может являться приложением (об этом говорилось ранее). Разумеется, что модули можно настраивать, меняя их поведение в зависимости от ситуации. Для этого предназначено две функции:

```javascript
myModule.run(function () {
    // код, находящийся здесь, будет выполнен на этапе создания модуля
    // сразу после того, как будут подгружены все зависимости

    // например, здесь можно запросить с сервера данные, важные для всего модуля
})

myModule.config(function() {
    // в этой функции можно настроить поведение провайдеров
    // крайне важная функция, к ней мы ещё вернёмся
})
```

## Провайдер

Провайдеры являются фабриками классов. Они создают готовые объекты, которые можно внедрять с помощью DI. Провайдеры являются основным способом расширения функциональности AngularJS. По своей сути, провайдер представляет собой объект, в котором находится единственная обязательная функция с строго регламентированным именем: `$get`.

```javascript
function someProvider() {
    this.$get = function() {
        return 42
    }
}
```

Помимо того, провайдер может включать любые методы, с помощью которых можно настроить создание объектов. Объекты, создаваемые провайдером, обычно называются *сервисы*.

Функция `$get` вызывается инъектором в процессе внедрения зависимостей. Поэтому если написать её тем или иным способом, то можно получить разные результаты: например, всякий раз будет создаваться новый объект, а может и отдаваться ссылка на один и тот же общий. Второй вариант широко применяется для обмена данными между разными частями приложения/модуля.

Для доступа к самому провайдеру следует добавить к имени сервиса слово `Provider`. Например, `$httpProvider`. Следует заметить, что далеко не у всех сервисов есть свой отдельный провайдер, к которому можно получить доступ, как в примере выше.

### Константа

Константа — это сервис, представляющий собой некую константу. Пример такого сервиса можно увидеть выше. Однако в AngularJS существуют функции для более удобного создания объектов, не имеющих отдельного провайдера, который не нужно настраивать. Для создания сервиса, отдающего некую константу, можно воспользоваться функцией `module.value`, выглядит это так:

```javascript
myModule.value("TheAnswer", 42)
```

Эта запись эквивалентна следующей:

```javascript
function someProvider() {
    this.$get = function() {
        return 42
    }
}

myModule.provide("TheAnswer", someProvider)
```

С той лишь разницей, что сокращённая запись не позволяет обращаться к `TheAnswerProvider` за ненадобностью. В качестве константы выступать может что угодно, главное не забывать, что это всегда будет одно и то же значение. Попробуйте проверить, что будет, если в качестве константы задать объект и менять его свойства из разных частей приложения.

### Фабрика

Фабрика это усложнённый вариант константы. Фабрика позволяет не только вернуть некоторое значение, но ещё и предварительно выполнить некоторые действия.

```javascript
myModule.factory("TheObject", function (TheAsnwer) {
    var obj = {
        property1: 1,
        property2: 2,
        answer: TheAnswer
    }

    obj.property3 = obj.property1 + obj.property2

    return obj
})
```

Обратите внимание, что я внедрил TheAsnwer в фабрику. Так же можно подключать любые зависимости. Сервисы могут и должны зависеть друг от друга.

Таким образом, я могу менять в некоторой степени поведение фабрики `TheObject`, поскольку она зависит от `TheAnswer`. Но лишь в некоторой степени.

### Сервис

Сервис это фабрика, которая всякий раз возвращает новый объект. Иными словами, запись

```javascript
myModule.factory("TheService", function(TheObject) {
    var service = function(obj) {
        this.obj = obj
    }

    return new service(TheObject)
})
```

Можно сократить до

```javascript
function service (TheObject) {
    this.obj = TheObject
}

myModule.service("TheService", service)
```

Но что если в этом случае мы хотим менять передаваемый в процессе создания сервиса параметр? В этом случае нам и нужен полноценный провайдер.

В сущности, AngularJS все вышеописанные методы реализует через вызов `module.provider`, они нужны лишь для удобства и сокращения записи. Полноценный сервис с провайдером же выглядит так:

```javascript
myModule.provider("TheService", function(TheObject) {
    var o = TheObject

    function service (obj) {
        this.obj = obj
    }

    this.setInitiator = function (initiator) {
        o = initiator
    }

    this.$get = function () {
        return new service(o)
    }
})
```

```javascript
var anotherModule = angular("AnotherModule", ["MyModule"])

anotherModule.configure(["TheServiceProvider", function(TheServiceProvider) {
    TheServiceProvider.setInitiator({
        name: "another value"
    })
}])

anotherModule.run(function(TheService) {
    console.log(TheService.obj)

    // выведет { name: "another value" }
})
```

## Директивы

Хорошо, но что если нам нужно не только сделать какой-то сервис или модуль. Что если мы хотим реализовать что-то подобное директиве ngRepeat? Разумеется, AngularJS позволяет делать и это.

Рассмотрим, что AngularJS делает, когда встречает:

1. Выражение
2. DOM

### $parse

Эта функция превращает любое допустимое выражение AngularJS в *функцию*. Эту функцию затем можно вызвать, передав в неё 1 или 2 параметра:

```javascript
var expr = $parse("user.data")
console.log(expr($scope))
// если $scope.user.data имеет значение, то оно будет выведено в консоль
```

Вторым параметром можно передать локальные переменные, с помощью которых можно временно переопределить переменные внутри контекста — первого параметра.

Именно с помощью этой функции AngularJS и осуществляет связывание данных и вообще всё, что использует выражения.

В ваших приложениях эта функция вам почти никогда не понадобится, но знать о её существовании полезно.

### $compile

$compile делает то же самое, что и $parse, но для HTML. Например

```javascript
var template = $compile("<p>{ { name } }</p>")
console.log(template({name: "Ivan"}))
// выведет <p>Ivan</p>
```

То есть это часть шаблонизатора AngularJS, осуществляющая привязку области видимости к шаблону.

Эта функция тоже вряд ли вам понадобится, но опять же знать о её существовании полезно.

### Первая директива

Теперь, когда мы знаем, как AngularJS обрабатывает выражения и HTML, можно попробовать написать первую директиву. Я не буду описывать все возможные параметры, опишу лишь те, что обычно используются.

```javascript
myModule.directive("greet", function () {
    return {
        template: "<p>Привет, { { name } }</p>",
        replace: true,
        scope: {},

        link: function (scope, element, attributes) {
            scope.name = "Иван"
        }
    }
})

<div greet></div>
```

В результате работы этой директивы вместо `<div>` будет выведено `<p>Привет, Иван</p>`. Параметр `replace` позволяет определить, будет ли директива целиком замещать DOM, которому применена, или же встраиваться внутрь него. Параметр `template` можно заменить на `templateUrl` и подключать шаблон из файла.

Наиболее важными параметрами здесь являются `scope` и `link`. Последний — это функция, осуществляющая привязку `scope` к шаблону (см. выше про `$compile`). Ну а `scope` позволяет изолировать область видимости внутри директивы. Эти два параметра следует указывать практически всегда.

Есть также параметр `compile`, который позволяет задать обработчик шаблона перед связыванием его с `link`, но он используется довольно редко.

#### Процесс компиляции в AngularJS

1. Сначала шаблон парсится стандартными средствами браузера. Важно понять, что шаблон должен быть допустимым HTML, иначе ничего не заработает.
2. Вызывается `$compile`, который обрабатывает выражения и составляет список обнаруженных директив. Директивы для каждого тега сортируются в порядке важности (его можно указывать при разработке директивы), затем вызываются функции `compile` у каждой из директив. В этих функциях директива имеет возможность изменить DOM по своему усмотрению. Результатом этого этапа будет одна общая функция линковки, включающая в себя также и все функции `link` директив.
3. Вызывается функция, полученная на этапе 2, которая в свою очередь вызывает функции `link` всех директив, которые могут привязывать обработчики событий и т.д.
4. Получаем DOM с включенным двойным связыванием, который может динамически меняться.

Директива практически всегда имеет функцию `link` и практически всегда не имеет функции `compile`.

### Полный код создания директивы

Хотя для простоты вы можете вообще возвращать в `angular.directive` функцию `link`:

```javascript
myModule.directive("simple", function() {
    return function(scope, element, attributes) {}
})
```

Это используется довольно редко. Чаще всего используется вариант из раздела «Первая директива». Однако есть и максимально полный вариант.

```javascript
myModule.directive('directiveName', function factory(injectables) {
    var directiveDefinitionObject = {
        // приоритет директивы (см. выше)
        priority: 0,
        // шаблон, заданный явно
        template: '<div></div>',
        // шаблон, заданный в виде ссылки или выражения
        templateUrl: 'directive.html',
        // заменять ли исходный DOM на шаблон
        replace: false,
        // включить ли некоторые части исходного DOM в шаблон
        transclude: false,
        // ограничить применение директивы
        restrict: 'A',
        // создавать/не создавать замыкание области видимости
        scope: false,
        // контроллер для директивы
        controller: function($scope, $element, $attrs, $transclude, otherInjectables) {
        },
        // здесь можно изменять исходный DOM
        compile: function compile(tElement, tAttrs, transclude) {
            return {
                pre: function preLink(scope, iElement, iAttrs, controller) {},
                post: function postLink(scope, iElement, iAttrs, controller) {}
            }
        },
        // здесь находится основная функциональность директивы
        link: function postLink(scope, iElement, iAttrs) {
        }
    }
    return directiveDefinitionObject
});
```

### Ограничение применимости

Поскольку в AngularJS существует несколько способов добавить директивы в DOM, вы можете отключить некоторые из них для вашей директивы. Если параметр `restrict` не задан, то директивы можно добавлять лишь в качестве атрибутов к элементам HTML. Другие возможные значения выглядят так:

- E: только в качестве собственного элемента DOM: `<my-directive></my-directive>`
- A: в качестве атрибута: `<div my-directive></div>`
- C: в качестве CSS-класса: `<div class="my-directive: value"></div>`
- M: в качестве комментария: `<!-- directive: my-directive value -->`

Эти значения можно комбинировать, например так: `restrict: "AC"`.

### Изоляция области видимости

Изоляция области видимости обладает ещё одним крайне важным свойством: сокращение кода при получении параметров директивы. Рассмотрим уже известную директиву `greet`.

```javascript
myModule.directive("greet", function ($parse) {
    return {
        template: "<p>Привет, { { name } }</p>",
        replace: true,
        scope: {},

        link: function(scope, element, attributes) {
            scope.name = $parse(attributes["greet"])(scope)
        }
    }
})

<div greet="Иван"></div>
```

Как видно, для извлечения нужного значения требуется проделать довольно некрасивую операцию. К счастью, в AngularJS это можно сделать намного проще.

```javascript
myModule.directive("greet", function ($parse) {
    return {
        template: "<p>Привет, { { greet } }</p>",
        replace: true,
        scope: {
            greet: "@"
        }
    }
})

<div greet="Иван"></div>
```

Добавив к замыканию области видимости свойство, имя которого совпадает с именем атрибута (а директива это тоже атрибут), а значением является `@`, можно автоматически передать значение атрибута в замыкание. Только обратите внимание, что в шаблоне имя переменной тоже поменялось. В таком простом случае функцию `link` вообще можно удалить, что и было сделано.

Следует заметить, что если написать

```javascript
<div greet="{ { someName } }"></div>
```

И определить `someName` где-то ещё, то директива заработает как и ожидается, но только в одну сторону. Можно поступить несколько иначе:

```javascript
scope: {
    greet: "="
}

<div greet="someName"></div>
```

Такая запись позволяет осуществлять полноценное двойное связывание между директивой и внешним миром. Например, вы можете добавить `<input ng-model='greet'>` в шаблон директивы и наблюдать, как `someName` вне её будет успешно меняться при изменении значения в поле ввода.

#### Продвинутый вариант области видимости

Существует и ещё более продвинутый вариант изоляции области видимости, позволяющий не только связывать данные, но и передавать функциональность из внешнего контроллера в директиву.

```javascript
template: "<button ng-click='greet()'>Greet!</button>"
scope: {
    greet: "&"
}

<div greet="sayHello()"></div>

>> Где-то в контроллере

$scope.sayHello = function() { alert("Привет!") }
```

Однако и это ещё не всё. Мы можем передавать параметры методу, который вызывается из контроллера. Делается это довольно необычно:

```javascript
template: "<input ng-model='name'><button ng-click='greet({name: name})'>Greet!</button>"
scope: {
    greet: "&"
}

<div greet="sayHello(name)"></div>

>> Где-то в контроллере

$scope.sayHello = function(name) { alert("Привет, " + name + "!") }
```

**Важно** Обратите внимание как передаются параметры в шаблоне директивы. Попробуйте создать две директивы и понаблюдать, как они будут работать независимо друг от друга:

```javascript
<div greet="sayHello(name)"></div>
<div greet="sayHello(name)"></div>
```

Вводимые в поле ввода имена будут уникальными для каждой директивы и не помешают друг другу, несмотря на несколько смущающую запись. `sayHello(name)` — параметр здесь это *имя свойства* объекта, передаваемого из директивы.

Всё вышеописанное легко достигается вообще без использования функции `link`. Однако если вы хотите самостоятельно обрабатывать некие события браузера, она вам понадобится.

#### Что на самом деле делают @, =, &?

**@** создаёт одностороннее связывание данных из родительской области видимости.

**=** позволяет изолированному в области видимости идентификатору участвовать в связывании (обратите внимание, как сильно это отличается от @)

**&** создаёт *делегат*. Если вы работали с C#, то знакомы с понятием делегата. Если же нет, то я рекомендую обратиться к другим источникам, хотя в общем-то для работы с AngularJS это и не обязательно.

### Подмена

Предположим, что мы хотим создать директиву, показывающую диалоговое окно, внутри которого расположен произвольный HTML. В этом случае изоляции области видимости из атрибутов будет недостаточно. К счастью, AngularJS предлагает простую механику transclusion.

```javascript
<div dialog>
    <h1>Диалог</h1>
    <p>Это диалог</p>
</div>

angular.directive("dialog", function () {
    return {
        template: "<div class='dialog' ng-transclude></div>",
        replace: true,
        transclude: true,
        scope: {}
    }
})
```

Я намеренно опустил логику создания диалога и сильно упростил итоговый HTML в `template`. Для настоящей директивы понадобится добавить правильную разметку с кнопкой закрытия, кнопками действия (которые могут настраиваться через дополнительные атрибуты), повешать обработчики событий в функции `link` и т.д. Однако этот пример позволяет быстро понять, как пользоваться функцией подмены разметки.

*Важно*: содержимое тега с директивой ngTransclude **будет сохранено**. Новая разметка будет добавлена к нему.

### Взаимодействие директив

Директивы могут взаимодействовать друг с другом с помощью контроллеров. Одна директива может зависеть от другой и вызывать методы и свойства её контроллера.

```javascript
myModule.directive("capital", function () {
    return {
        scope: {
            capital: "@"
        },
        controller: function ($scope) {
            $scope.tell = function() {
                console.log($scope.capital)
            }
        }
    }
})

myModule.directive("country", function () {
    return {
        require: "capital",
        scope: {
            country: "@"
        },
        // имя capitalController не важно, внедрение происходит
        // через require
        link: function (scope, element, attributes, capitalController) {
            console.log(scope.country + " — " + capitalController.tell())
        }
    }
})

<div country="Россия" capital="Москва"></div>
```

Читайте так же статьи по теме:

* [Улучшение логирования в AngularJS с помощью декораторов](https://makeomatic.ru/blog/2014/01/06/AngulaJS_logging/)
* [Ускоряем $digest цикл в AngularJS](https://makeomatic.ru/blog/2014/03/28/Digest_angular/)
* [Последовательная асинхронная инициализация AngularJS приложений с использованием промисов](https://makeomatic.ru/blog/2014/04/04/Initialization_angularjs/)
* [“Безопасный” $apply в Angular.JS](https://makeomatic.ru/blog/2014/01/30/Apply_in_AngularJS/)
* [Работа с REST API в AngularJS](https://makeomatic.ru/blog/2013/12/27/work_with_REST_API_AngularJS/)
* [Все о пользовательских фильтрах в AngularJS](https://makeomatic.ru/blog/2014/06/06/custom_filters_Angular/?ym_playback=linkmap&ym_cid=15629977#more)
* [Как использовать ngMessages в AngularJS](https://makeomatic.ru/blog/2014/05/21/ngMessage/#ym_playback=linkmap&ym_cid=15629977)
* [Data service для работы с API в AngularJS](https://makeomatic.ru/blog/2014/04/22/Module_in_AngularJS/#ym_playback=linkmap&ym_cid=15629977)
* [Последовательная асинхронная инициализация Angular.JS приложений с использованием промисов](https://makeomatic.ru/blog/2014/04/04/Initialization_angularjs/#ym_playback=linkmap&ym_cid=15629977)
* [Дебаггинг приложения на AngularJS через консоль](https://makeomatic.ru/blog/2014/08/12/debugging_AngularJS_app/)
* [Разбираемся с системой событий $emit, $broadcast и $on в $scope и $rootScope Ангуляра](https://makeomatic.ru/blog/2014/07/10/Angular_scope_rootScope/)
* [Эффективное сквозное тестирование с Protractor. Часть 1](https://makeomatic.ru/blog/2015/01/05/Protractor_testing/)



