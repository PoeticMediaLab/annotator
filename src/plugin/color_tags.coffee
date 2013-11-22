# Color based tags plugin allows users to tag thier annotations with color
# stored in an Array on the annotation as color_tags.
class Annotator.Plugin.ColorTags extends Annotator.Plugin
  # HTML templates for the plugin UI.
  html:
    element: """
             <div class="annotator-color-tags">
             </div>
             """

  options:
    color_tags: []
    limit: null
    classForSelectedColor: 'selected'
    colorsForCategory: {}

  events:
    '.tag-color click'                 : 'toggleSelectedColor'
    'annotationEditorShown'            : 'updateEditor'
    'annotatorSelectedCategoryChanged' : 'updateSelectedColorForCurrentCategory'

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
    colors  = @options.color_tags

    element.html(
      $.map(colors,(color) ->
        "<span class='tag-color' style='background-color:"+color+"'data-color='"+color+"'></span>"
      ).join(' ')
    )
    @annotator.editor.element.find(@annotationField()).after element

    @annotator.viewer.addField
      load: @updateViewer

    @field = @annotator.editor.addField
      submit: @setColorsForCategories
      load:   @updateColorsForCategories

    @input = $(@field).find(":input")

  constructor: (element, options) ->
    super element, options
    if options.limit?
      @options.color_tags = options.colors.slice(0, options.limit)
    else
      @options.color_tags = options.colors

    @options.limit      = options.limit

  toggleSelectedColor: (event) ->
    $(event.target).toggleClass(@options.classForSelectedColor)
    if $(event.target).hasClass(@options.classForSelectedColor)
      @addColorForSelectedCategory $(event.target).data('color')
    else
      @removeColorForSelectedCategory $(event.target).data('color')

  updateEditor: (editor, annotation) ->
    @fixEditorHeight editor, annotation
    category = @annotator.plugins['Categories'].selectedCategory().html()
    @updateSelectedColorForCurrentCategory(category)

  addColorForSelectedCategory: (color)->
    category = @annotator.plugins['Categories'].selectedCategory().html()
    @options.colorsForCategory[category] ||= []
    @options.colorsForCategory[category].push color

    #update color tag field value
    @input.val JSON.stringify(@options.colorsForCategory)

  removeColorForSelectedCategory: (color) ->
    category = @annotator.plugins['Categories'].selectedCategory().html()

    @options.colorsForCategory[category] ||= []
    colorIndex =  @options.colorsForCategory[category].indexOf(color)

    if (colorIndex > -1)
      @options.colorsForCategory[category].splice(colorIndex, 1)

    #update color tag field value
    @input.val JSON.stringify(@options.colorsForCategory)

  #TODO: DRYout by using method from categories plugin
  annotationField: ->
    @element.find("textarea:first")

  updateViewer: (filed, annotator) ->
    colorsForCategory = annotator.categoriesColors
    categoriesDom = $(filed).parent().find("div.categories")

    if colorsForCategory && colorsForCategory.length > 1
      colorsForCategory = JSON.parse(colorsForCategory)
      $.each Object.keys(colorsForCategory), (i, category) ->
        categoryDom         = categoriesDom.find "#"+category.replace(RegExp(" ", "g"), "_")
        colorsForCategories = colorsForCategory[category]
        categoryColorDom = $('<div>').addClass('category-colors')

        $.each colorsForCategories, (i, color) ->
          categoryColorDom.append($("<span class='category-color'>").css('background-color',color))
        categoryDom.append(categoryColorDom)

  colorTagsWrapperDom: ->
    @element.find('.annotator-color-tags')

  fixEditorHeight: (editor, annotation) ->
    annotatorView         = $(editor.element)
    colorTagWrapperHeight = @colorTagsWrapperDom().height()
    annotatorForm         = annotatorView.find('form.annotator-widget')

    # Lets increase height of ediotr if the height of color-tags's wrapper is greator than editor's height
    if annotatorForm.height() < colorTagWrapperHeight
      controlHeight         = annotatorView.find('.annotator-controls').height()

      # 2px border for each color tag
      colorTagBorderHeight  = @options.color_tags.length * 2
      annotatorForm.height controlHeight + colorTagWrapperHeight + colorTagBorderHeight

  setColorsForCategories: (field, annotator) ->
    input = $(field).find(":input")
    annotator.categoriesColors = input.val()

  updateSelectedColorForCurrentCategory: (category) ->
    colorTags = @colorTagsWrapperDom().find('span.tag-color')
    colorTags.removeClass @options.classForSelectedColor
    colorsForCategory = @options.colorsForCategory[category]
    that = @

    if colorsForCategory
      $.each colorsForCategory, (i, color) ->
        tagWithColor = that.colorTagsWrapperDom().find("span[data-color='"+color+"']")
        tagWithColor.addClass that.options.classForSelectedColor

  updateColorsForCategories: (field, annotator) ->
    input = $(field).find(":input")
    input.val(annotator.categoriesColors).hide().addClass 'categories-colors'
