# Categoris plugin allows users to add multiple annotation for same selection
class Annotator.Plugin.Categories extends Annotator.Plugin
  # HTML templates for the plugin UI.
  html:
    element: """
             <li class="annotator-categories">
             <h4>"""+Annotator._t('Categories')+"""</h4>
             <br clear="all">
             </li>
             """

  options:
    #Testing the UI we'll load color codes from server
    categoires: ['Sourcing', 'Context', 'Close Reading', 'Corrobration'],
    categorieAnnotations:  {
    'Sourcing':     "Hello world its Sourcing",
    'Context':      "Hello world its Context",
    'Close Reading': "I am Close Reading"
    }

  events:
    '.annotator-category click' : "toggleSelectedCategory"
    'annotationsLoaded'         : "initAnnotations"
    'beforeAnnotationCreated'   : "setupEditor"

  # The field element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  field: null

  # The input element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  input: null

  # Public: Initialises the plugin and adds color tags fields wrapper to annotatro wrapper(editor and viewer)
  # Returns nothing.
  pluginInit: ->
    element = $(@html.element)
    categories  = @options.categoires

    element.find('h4').after(
      $.map(categories,(category) ->
        "<div class='annotator-category'>"+category+"</div>"
      ).join(' ')
    )
    @element.find('.annotator-listing .annotator-item:first-child').after element

  constructor: (element, categories) ->
    super element, categories
    @options.categories = categories if categories

  setSelectedCategory: (currentCategory) ->
    @element.find('.annotator-category').removeClass('selected')
    $(currentCategory).addClass('selected')

  toggleSelectedCategory: (event) ->
    @setTextForCategory @selectedCategory().html(), @annotationField().val()
    text = @getTextForCategory $(event.target).html()
    @annotationField().val(text)
    @setSelectedCategory event.target

  selectedCategory: ->
    @element.find('.annotator-category.selected')

  setupEditor: (annotation)->
    annotation.text  = "hello world"

  annotationField: ->
    @element.find("textarea:first")

  initAnnotations: (annotations) ->

  toggleSeleted: ->
    ""
  getTextForCategory: (category) ->
    @options.categorieAnnotations[category]

  setTextForCategory: (category, annotation) ->
    @options.categorieAnnotations[category] = annotation