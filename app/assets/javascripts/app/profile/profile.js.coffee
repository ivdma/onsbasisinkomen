angular.module("profile", ["User","Wish","State","angularFileUpload",'ng-breadcrumbs','matchMedia'])
.config [
  "$routeProvider"
  ($routeProvider) ->
    $routeProvider
    .when "/menschen/:userId",
      templateUrl: "/assets/profile.html"
      controller: "ProfileViewController"
      label: "Profil"
      resolve:
        thisuser: [
          "User"
          "$route"
          (User, $route) ->
            User.get($route.current.params.userId).then (user) ->
              user
        ]

]

.controller "ProfileViewController", [
  "$scope"
  "Security"
  "thisuser"
  "User"
  "Wish"
  "State"
  "$upload"
  "$http"
  "breadcrumbs"
  "$cookies"
  "screenSize"
  "$modal"
  "$routeParams"
  "filterFilter"

  ($scope, Security, user, UserModel, Wish, State, $upload, $http, breadcrumbs, $cookies, screenSize, $modal,  $routeParams, filterFilter) ->

    $scope.user = user
    $scope.default_avatar = if user.avatar.avatar.url == '/assets/team/team-member.jpg' then true else false

    $scope.mobile = screenSize.is('xs')
    $scope.largeScreen = screenSize.is('lg, md')

    $scope.user_states = []

    $scope.skip = []
    $scope.currentTab = []
    $scope.tabs = ['wishes', 'image', 'states', 'support', 'gewinnspiel']


    $scope.initial_states = [
      'Renter_in',
      'Student_in',
      'Kind',
      'Frau',
      'Mann',
      'Elternteil',
      'Unternehmer_in',
      'Arbeitnehmer_in',
      'Schüler_in',
      'Sozialleistungsbeziehende_r',
      'Arbeitslose_r',
      'Künstler_in',
      'Urheber_in',
      'Sportler_in',
      'Freiberufler_in',
      'Alleinerziehende_r',
      'Ehrenamtliche_r',
      'Manager_in',
      'Migrant_in',
      'Mensch mit Behinderungen',
      'Aussteiger_in',
      'Akademiker_in',
      'Wissenschaftler_in, Lehrende_r',
      'Beamte_r',
      'in sozialem Beruf tätig',
      'in der Sozialverwaltung tätig'
    ]


    # $scope.tabtype = if $scope.mobile then 'pills' else ''
    # $scope.verticaltabs = if $scope.mobile then 'true' else 'false'

    breadcrumbs.options =
      Profil: user.name + "s Profil"
    #$scope.breadcrumbs = breadcrumbs

    $scope.wish_form = {}
    $scope.state_form = {}


    $scope.$watch (->
      Security.is_own_profile(user.id)
    ), (newVal, oldVal) ->
      $scope.own_profile = newVal
      return

    Wish.forUser(user.id).then (wishes) ->
      $scope.user_wishes = wishes

      if $cookies.initial_wishes && $cookies.initial_wishes != ''  && $cookies.initial_wishes != ';'
        $scope.wish_form.new_wish = $cookies.initial_wishes.replace(';','').replace(';','')
        $cookies.initial_wishes = '' if $scope.user_wishes.length > 0


    #initialize default states
    $scope.states = []
    angular.forEach $scope.initial_states, (statename) ->
      $scope.states.push
        text: statename
        visibility: false
        selected: false
        user_state_id: false
        is_default_state: true


    State.forUser(user.id).then (user_states) ->

      angular.forEach user_states, (user_state) ->
        is_default_state = false
        angular.forEach $scope.states, (state,key) ->
          if state.text == user_state.text
            is_default_state = true
            $scope.states[key].selected = true
            $scope.states[key].visibility = user_state.visibility
            $scope.states[key].user_state_id = user_state.userStateId
        if !is_default_state
          $scope.states.push
            text: user_state.text
            visibility: user_state.visibility
            user_state_id: user_state.userStateId
            selected: true
            is_default_state: false


    $scope.changeVisibility = (state) ->
      if state.user_state_id
        new State(
          id: state.user_state_id
          visibility: !state.visibility
          forStatesUser: '_users'
        ).update()

    $scope.addCustomState = () ->
      new_state =
        text: $scope.state_form.new_custom_state
        visibility: false
        selected: true
        is_default_state: false

      new_state.forStatesUser = 's'
      new State(new_state).create().then (response) ->
        new_state.user_state_id = response.userStateId
        $scope.states.push new_state
        $scope.state_form.new_custom_state = ""

    $scope.stateClicked = (state) ->

      if !state.selected #ADD
        state.forStatesUser = 's'
        new State(state).create().then (response) ->
          $scope.states[$scope.states.indexOf(state)].user_state_id = response.userStateId
      else
        if state.user_state_id #DELETE
          #"/api/{{forUser}}state{{forStatesUser}}/{{id}}
          new State(
            id: state.user_state_id
            forStatesUser: '_users'
          ).delete().then ->
            $scope.states[$scope.states.indexOf(state)].selected = false
            $scope.states[$scope.states.indexOf(state)].user_state_id = false


    $scope.$watch "states|filter:{selected:true}", ((nv) ->
      $scope.user_states = nv.map((state) ->
        state
      )
      return
    ), true


    UserModel.suggestions(user.id).then (suggestions) ->
      $scope.suggestions = suggestions


    $scope.new_name = user.name

    $scope.skip_section = (section) ->
      $scope.skip[section] = true
      angular.forEach $scope.tabs, (tabname,key) ->
        if tabname == section
          $scope.currentTab[$scope.tabs[key]] = false
          $scope.currentTab[$scope.tabs[key + 1]] = true

    $scope.setNewsletterFlag = () ->
      $http.put("/users.json",
        user:
          newsletter: true
      )

    $scope.onFileSelect = ($files) ->

      #$files: an array of files selected, each file has name, size, and type.
      i = 0

      while i < $files.length
        file = $files[i]
        method: 'PUT'
        $scope.upload = $upload.upload(
          url: "/users.json"
          method: 'PUT'
          file: file
          fileFormDataName: 'user[avatar]'
        ).progress((evt) ->
          return
        ).success((data, status, headers, config) ->
          Security.requestCurrentUser()
          $scope.user.avatar.avatar.url = data.avatar.avatar.url
          $scope.default_avatar = false
          if $scope.currentTab.image
            $scope.skip_section('image')
          return
        )
        i++
      return


    $scope.open = () ->
      modalInstance = $modal.open(
        templateUrl: "/assets/edit_profile.html"
        controller: EditProfileCtrl
        size: 'lg'
        resolve:
          userdata: user
      )
      return

    EditProfileCtrl = ($scope, $modalInstance, $route, $location) ->

      $scope.register_user = user
      $scope.delete_account_check = false

      $scope.update_profile = ->
        $scope.submitted = true
        $scope.serverMessage = false
        input =
          user: $scope.register_user

        $http.put("/users.json", input)
        .success((data, status, headers, config) ->
          $modalInstance.dismiss "done"
          $route.reload()
          $scope.submitted = false
        ).error (data, status, headers, config) ->
          $scope.serverMessage = data.email
          $scope.submitted = false
          return

      $scope.delete_account = ->
        input =
          user:
            id: user.id
        $http.delete("/users.json", input)
        .success( ->
          Security.logout()
          $modalInstance.dismiss "done"
          $location.path("/")
        )
        return

      $scope.ok = ->
        $modalInstance.dismiss "done"
        return

      $scope.cancel = ->
        $modalInstance.dismiss "cancel"
        return

    if $routeParams['edit_profile']
      $scope.open()


    $scope.getStateSuggestions = (q) ->
      State.suggestions(q).then (states) ->
        return states

    $scope.getSuggestions = (q) ->
      Wish.suggestions(q).then (wishes) ->
        r = []
        angular.forEach wishes, (item) ->
          r.push
            text: item.text
            count: item.othersCount
            create: item.create
        console.log r
        return r

    $scope.selectedSuggestion = (item) ->
      $scope.wish_form.new_wish = item.text
      $scope.hide_popover = true

    $scope.me_too = (wish) ->
      new Wish(
        forUser: 'user_'
        wish_id: wish.wishId
      ).create()
      .then (response) ->
        if $scope.own_profile
          $scope.suggestions.splice($scope.suggestions.indexOf(wish), 1)
          $scope.user_wishes.push response
        else
          if !response.meToo
            $scope.user_wishes[$scope.user_wishes.indexOf(wish)].meToo = false
            $scope.user_wishes[$scope.user_wishes.indexOf(wish)].othersCount -= 1
          else
            $scope.user_wishes[$scope.user_wishes.indexOf(wish)] = response



    $scope.addWish = ->

      $scope.hide_popover = false

      if $scope.wish_form.new_wish.count
        $scope.wish_form.new_wish = $scope.wish_form.new_wish.text

      for wish in $scope.user_wishes
        if wish.text == $scope.wish_form.new_wish
          alert 'Dieses Vorhaben hast du schon angelegt.'
          return false

      new Wish(
        text: $scope.wish_form.new_wish
        story: $scope.wish_form.story
      ).create()
      .then (response) ->
        $scope.user_wishes.unshift response
        $scope.wish_form.new_wish = ""
        $scope.wish_form.story = ""


    $scope.editStory = (user_wish) ->
      $scope.edit_story = user_wish
      if !user_wish.edited_story
        $scope.user_wishes[$scope.user_wishes.indexOf(user_wish)].edited_story = user_wish.story

    $scope.cancelStoryEditing = (user_wish) ->
      $scope.edit_story = false
      $scope.user_wishes[$scope.user_wishes.indexOf(user_wish)].edited_story = false

    $scope.updateStory = (user_wish) ->
      $scope.edit_story = false
      $scope.user_wishes[$scope.user_wishes.indexOf(user_wish)].story = user_wish.edited_story
      new Wish(
        id: user_wish.id
        story: user_wish.edited_story
        forUser: 'user_'
      ).update()


    $scope.removeWish = (user_wish) ->
      new Wish(
        id: user_wish.id
        forUser: 'user_'
      ).delete()
      $scope.user_wishes.splice($scope.user_wishes.indexOf(user_wish), 1)
]
