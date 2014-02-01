# Public: Plugin for managing user permissions under the rather more specialised
# permissions model.
#
# element - A DOM Element upon which events are bound. When initialised by
#           the Annotator it is the Annotator element.
# options - An Object literal containing custom options.
#
# Examples
#
#   new Annotator.plugin.AnnotateItPermissions(annotator.element)
#
# Returns a new instance of the AnnotateItPermissions Object.
class Annotator.Plugin.AnnotatorStudioPermissions extends Annotator.Plugin.Permissions

  # A Object literal of default options for the class.
  options:

  # Displays an "Anyone can view this annotation" checkbox in the Editor.
    showViewPermissionsCheckbox: true

  # Displays an "Anyone can edit this annotation" checkbox in the Editor.
    showEditPermissionsCheckbox: true

  # Abstract user groups used by userAuthorize function
    groups:
      everyone:    'everyone'
      instructors: 'instructors'
      class:       'class'
      me:          'me'

    userId: (user) -> user.userId
    userString: (user) -> user.userId

  # Public: Used by AnnotateItPermissions#authorize to determine whether a user can
  # perform an action on an annotation.
  #
  # This should do more-or-less the same thing as the server-side authorization
  # code, which is to be found at
  #   https://github.com/okfn/annotator-store/blob/master/annotator/authz.py
  #
  # Returns a Boolean, true if the user is authorised for the action provided.
    userAuthorize: (action, annotation, user) ->
      permissions = annotation.permissions or {}
      action_field = permissions[action] or []

      if @groups.everyone in action_field
        return true
      else if user?
        if user == annotation.user
          return true
        else if user.groups?
          groups = @groups
          $.each Object.keys(groups), (group) ->
            if groups[group] in user.groups
              return true
          return false
        else
          return @groups.me in action_field and user.userId == annotation.user

      else
        return false

  # Default permissions for all annotations. Anyone can
  # read, but only annotation owners can update/delete/admin.
    permissions: {
      'read':   ['everyone']
      'update': []
      'delete': []
      'admin':  []
    }

  events:
    'annotationsLoaded': 'updateAnnotationsVisiablity'

  constructor: (element, options) ->
    super element, options

  # Public: Initializes the plugin and registers fields with the
  # Annotator.Editor and Annotator.Viewer.
  #
  # Returns nothing.
  pluginInit: ->
    return unless Annotator.supported()

    @annotator.subscribe('beforeAnnotationCreated', this.addFieldsToAnnotation)

    self = @
    createCallback = (method, type) ->
      (field, annotation) -> self[method].call(self, type, field, annotation)

    # Set up user and default permissions from auth token if none currently given
    if !@user and @annotator.plugins.Auth
      @annotator.plugins.Auth.withToken(this._setAuthFromToken)

    if @options.showViewPermissionsCheckbox == true
      @annotator.editor.addField({
        type:   'checkbox'
        label:  Annotator._t('Who can <strong>view</strong> this annotation')
        load:   createCallback('updatePermissionsField', 'read')
        submit: createCallback('updateAnnotationPermissions', 'read')
      })

    if @options.showEditPermissionsCheckbox == true
      @annotator.editor.addField({
        type:   'checkbox'
        label:  Annotator._t('Allow anyone to <strong>edit</strong> this annotation')
        load:   createCallback('updatePermissionsField', 'update')
        submit: createCallback('updateAnnotationPermissions', 'update')
      })

    # Setup the display of annotations in the Viewer.
    @annotator.viewer.addField({
      load: this.updateViewer
    })

    # Add a filter to the Filter plugin if loaded.
    if @annotator.plugins.Filter
      @annotator.plugins.Filter.addFilter
        label: Annotator._t('User')
        property: 'user'
        isFiltered: (input, user) =>
          user = @options.userString(@user)

          return false unless input and user
          for keyword in (input.split /\s*/)
            return false if user.indexOf(keyword) == -1

        true


  # Event callback: Appends the @options.permissions, @options.user and
  # @options.consumer objects to the provided annotation object.
  #
  # annotation - An annotation object.
  #
  # Examples
  #
  #   annotation = {text: 'My comment'}
  #   permissions.addFieldsToAnnotation(annotation)
  #   console.log(annotation)
  #   # => {text: 'My comment', user: 'alice', consumer: 'annotateit', permissions: {...}}
  #
  # Returns nothing.
  addFieldsToAnnotation: (annotation) =>
    if annotation
      annotation.permissions = @options.permissions
      if @user
        annotation.user = @user.userId
        annotation.consumer = @user.consumerKey

  # Field callback: Updates the state of the "anyone canâ€¦" checkboxes
  #
  # action     - The action String, either "view" or "update"
  # field      - A DOM Element containing a form input.
  # annotation - An annotation Object.
  #
  # Returns nothing.
  updatePermissionsField: (action, field, annotation) =>
    field = $(field).show()
    input = field.find('input').removeAttr('disabled')

    # Do not show field if current user is not admin.
    #field.hide() unless this.authorize('admin', annotation)

    if action == 'read'
      $(field).html(@htlmForVisiblityOptions(annotation))

    # See if we can authorise with any old user from this consumer
    if @user and this.authorize(action, annotation || {}, {userId: '__nonexistentuser__', consumerKey: @user.consumerKey})
      input.attr('checked', 'checked')
    else
      input.removeAttr('checked')


  # Field callback: updates the annotation.permissions object based on the state
  # of the field checkbox. If it is checked then permissions are set to world
  # writable otherwise they use the original settings.
  #
  # action     - The action String, either "view" or "update"
  # field      - A DOM Element representing the annotation editor.
  # annotation - An annotation Object.
  #
  # Returns nothing.
  updateAnnotationPermissions: (type, field, annotation) =>
    annotation.permissions = @options.permissions unless annotation.permissions

    dataKey = type + '-permissions'
    if type == 'read'
      checkedGroups = $(field).find('input:checked')
      groups = []
      $.each checkedGroups, (group, i) ->
        groups.push $(@).data('group')

      annotation.permissions[type]= groups
    else
      if $(field).find('input').is(':checked')
        annotation.permissions[type] = [@options.groups.everyone]
      else
        annotation.permissions[type] = []

  updateAnnotationsVisiablity: (annotations) ->
    that = @
    $.each annotations, (i, annotation) ->
      console.info(@user)
      if !that.options.userAuthorize('read', annotation, @user)
        $(@.highlights).hide()

  htlmForVisiblityOptions: (annotation) ->
    groups      = @options.groups
    permissions = annotation.permissions['read']

    checkboxes = $.map(Object.keys(groups), (group) ->
      id    = "annotator-field-"+group
      input = if groups[group] in permissions
                "<input id='"+id+"' type='checkbox' name='read-permission' checked='checked' data-group='"+groups[group]+"' />"
              else
                "<input id='"+id+"' type='checkbox' name='read-permission' data-group='"+groups[group]+"' />"

      label = "<label for='"+id+"'>"+group+"</label>"

      input + label

    ).join(' ')

    message = $("<div>", {html: "Who can <strong>View</strong> this annotation?"})
    $("<div>").append(message).append(checkboxes)


  # Sets the Permissions#user property on the basis of a received authToken. This plugin
  # simply uses the entire token to represent the user.
  #
  # token - the authToken received by the Auth plugin
  #
  # Returns nothing.
  _setAuthFromToken: (token) =>
    this.setUser(token)