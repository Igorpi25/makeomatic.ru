title: Создание модели данных в Angular.js
subtitle: Взаимодействие с API и получение данных
date: 2014-09-18
author: Анна Аминева
gravatarMail: annafedotovaa@gmail.com
tags: [AngularJS, Javascript]
---

<div class='text-center'>
  ![Иллюстрация блокнота](/blog/images/modelling.jpg)
</div>
<br>

Когда я впервые коснулся Ангуляра, у меня уже был опыт работы с EmberJS и BackboneJS, а так же были определенные представления относительно клиентских фреймворков. На первый взгляд, порог вхождения был ниже, чем у других фреймворков. Это хорошо, так как за короткий срок вы можете добиться значительных результатов в его освоении.
<!-- more -->

Для меня большой проблемой стала модель данных. Ангуляр позволяет вам самим решать этот вопрос.  С одной стороны, это хорошо, так как дает нам достаточную свободу, но за свободу всегда приходится чем-то платить.

EmberJS и BackboneJS имеют свои собственные Model/Store (Ember) и Model/Collection (Backbone) решения, итак давайте посмотрим как я справился с этой проблемой в Angular.
Для начала я приведу достаточно простой пример взаимодействия с API, с помощью которого мы получаем данные в виде JSON.

```js Article.js
app.factory('Article', function($http, $q) {
  // Сохраняем адресс API
  var apiUrl = 'http://api.example.local';

  // Объявляем класс модели данных
  var ArticleModel = function(data){
    if (data) {
      this.setData(data);
    }
  };

  // Добавляем prototype методы каждому объекту
  ArticleModel.prototype.setData = function (data) {
    angular.extend(this, data);
  };

  ArticleModel.prototype.delete = function () {
    $http.delete(apiUrl + '/articles/' + this._id).success(function() {
       // Как-нибудь обрабатываем успешный запрос
    }).error(function(data, status, headers, config) {
       // Что-нибудь делаем в случае ошибки
    });
  };

  ArticleModel.prototype.update = function () {
    return $http.put(apiUrl + '/articles/' + this._id, this).success(function() {
      // Как-нибудь обрабатываем успешный запрос
    }).error(function(data, status, headers, config) {
      // Что-нибудь делаем в случае ошибки
    });
  };

  ArticleModel.prototype.create = function () {
    $http.post(apiUrl + '/articles/', this).success(function(r) {
      // Как-нибудь обрабатываем успешный запрос
    }).error(function(data, status, headers, config) {
      // Что-нибудь делаем в случае ошибки
    });
  };

  // Объявляем класс, который делаем запрос к API и возвращает объект модели с промисами
  var article = {

    findAll: function () {
      var deferred = $q.defer();
      var scope = this;
      var articles = [];
      $http.get(apiUrl + '/articles').success(function(array) {
        array.forEach(function(data) {
          articles.push(new ArticleModel(data));
        });
        deferred.resolve(articles);
      }).error(function() {
        deferred.reject();
      });
      return deferred.promise;
    },

    findOne: function (id) {
      var deferred = $q.defer();
      var scope = this;
      var data = {};
      $http.get(apiUrl + '/articles/' + id).success(function(data) {
        deferred.resolve(new ArticleModel(data));
      })
      .error(function() {
        deferred.reject();
      });
      return deferred.promise;
    },

    createEmpty: function () {
      return new ArticleModel({});
    }

  };

  return article;
});
```

Сейчас вы легко можете использовать ваши данные в контроллере, выводить в шаблоне, одним словом, делать с ними все, что хотите.
Используйте IndexController.js, чтобы загрузить все объекты из API. Используйте Check ShowController.js, для загрузки одного объекта из API:

```js IndexController.js
app.controller('IndexController', function($scope, Article) {
  // Получаем все статьи
 Articles.findAll().then(function(articles) {
   $scope.articles = articles;
 });
 });
```

```js ShowController.js
app.controller('ShowController', function($scope, Article) {

  // Получаем одну статью
  var articleId = 1; // You have to get articleId from route paramters or as you want
  Article.findOne(articleId).then(function(article) {
    $scope.article = article;
  });

});
```

Это только один из примеров применения. Существует несколько, а может и бесконечное количество вариантов получения данных с сервера, но данный вариант хорошо подошел для моего проекта.

В следующей части, я приведу более подробные и сложные примеры обработки данных в Ангуляр.

Все файлы для данного примера:

```js EditController.js
app.controller('EditController', function($scope, Article) {

  // Получаем одну статью
  var articleId = 1; // Вы должны получить Id статьи из параметров url
  Article.findOne(articleId).then(function(article) {
    $scope.article = article;
  });

  // Изменим и обновим
  $scope.article.title = "Some title";
  $scope.article.update();

  // Удалим
  $scope.article.delete();

  // Новая статья (создаем пустую модель)
  $scope.newArticle = Article.createEmpty();
  $scope.newArticle.title = "Some new title";
  $scope.newArticle.create();

});
```

```js NewController.js
app.controller('NewController', function($scope, Article) {

  // Новая статья (создаем пустую модель)
  $scope.article = Article.createEmpty();

});
```

```html article.edit.html
<!-- Когда вы находитесь в шаблоне и у вас есть форма, вы можете использовать такие формовые элементы:: -->

<form>
  <p><input type="text" name="title" ng-model="article.title"></p>
  <p><button type="button" ng-click="article.update()"></p>
  <p><button type="button" ng-click="article.delete()"></p>
</form>

<!-- NOTE: In this case do not forget to handle the success method on delete. For eg. redirect the user to another view -->

```

По мотивам Zoltan Radics
