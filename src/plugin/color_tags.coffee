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
    #Testing the UI we'll load color codes from server
    color_tags: ['red', 'blue', 'pink', 'red']

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
        "<span class='tag-color'></span>"
      ).join(' ')
    )
    @annotator.editor.element.find('.annotator-item textarea').after element

  constructor: (element, colors) ->
    @options.color_tags = colors if colors