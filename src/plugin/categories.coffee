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
    categoires: ['Sourcing', 'Context', 'Close Reading', 'Corrobration']

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
    @annotator.editor.element.find('.annotator-listing .annotator-item:first-child').after element

  constructor: (element, categories) ->
    @options.categories = categories if categories