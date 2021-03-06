window.App = angular.module('grundeinkommen', ['ui.bootstrap','meta','rails','ngRoute','ng-breadcrumbs','Security','ngCookies','angulartics','angulartics.google.analytics','login','reset_password','home','register','profile','wishpage','content','smoothScroll','faq','draw','drawfrontend', 'Support','djds4rce.angular-socialshare','admin','blog','boarding','Crowdbar','Crowdcard'])

.config [
  "$routeProvider"
  "$locationProvider"
  "MetaProvider"
  ($routeProvider, $locationProvider, MetaProvider) ->
    $locationProvider.html5Mode true
    $routeProvider
    .otherwise
      redirectTo: "/start"
    MetaProvider
      .when '/crowdapp',
        title: 'Crowdbar'
      .otherwise
        title: 'Ons basisinkomen'
]


.config (RailsResourceProvider) ->
  RailsResourceProvider.rootWrapping(false)


.controller "AppCtrl", [
  "$scope"
  "$rootScope"
  "Security"
  "breadcrumbs"
  "Home"
  "Crowdbar"
  "$location"
  "$modal"

  ($scope, $rootScope, Security, breadcrumbs, Home, Crowdbar, $location, $modal) ->

    $scope.current = Security

    $scope.breadcrumbs = breadcrumbs

    $rootScope.$on '$routeChangeStart', ->
      $rootScope.show_spinner = true
    $rootScope.$on '$routeChangeSuccess', ->
      $rootScope.show_spinner = false


    $scope.getStatus = (path) ->
      if $location.path().indexOf(path) == 0
        "current"
      else
        ""

    Crowdbar.verify().then (has_crowdbar) ->
      $scope.current.setFlag('hasCrowdbar',has_crowdbar)
      $scope.current.setFlag('hasHadCrowdbar', true) if has_crowdbar

    #STATS
    Home.query().then (home) ->
      $scope.home = home

      $scope.home.financedIncomes = []

      $scope.percentage = home.percentage

      for fi in [1..home.totallyFinancedIncomes]
        $scope.home.financedIncomes.push "#{fi}. Basisinkomen met €12.000 met Crowdfunding gefinancieerd!"

    # CurrentDate = new Date()
    # Verlosung = new Date("September, 19, 2014")
    # DayCount = (Verlosung - CurrentDate) / (1000 * 60 * 60 * 24)
    # $scope.daysLeft = Math.round(DayCount)

    $scope.bge_info = ->
      $modal.open
        templateUrl: "/assets/was_ist_grundeinkommen.html"
        size: 'lg'

    return
]

#################################################

.run [
  "$route"
  "$rootScope"
  "$location"
  "Security"
  "$FB"
  "Meta"
  ($route, $rootScope, $location, Security, $FB, Meta) ->
    Security.requestCurrentUser()
    Meta.init()
    $FB.init('1410947652520230')
    original = $location.path
    $location.path = (path, reload) ->
      if reload is false
        lastRoute = $route.current
        un = $rootScope.$on("$locationChangeSuccess", ->
          $route.current = lastRoute
          $rootScope.show_spinner = false
          un()
          return
        )
      original.apply $location, [path]
]