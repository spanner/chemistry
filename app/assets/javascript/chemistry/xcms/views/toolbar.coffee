## Toolbar
#
# Attaches a formatting toolbar to a DOM element.
#
class Cms.Views.BaseToolbar extends Cms.View
  template: ""
  className: "ed-toolbar"
  buttons: []


  initialize: (opts={}) =>
    @target_el = opts.target

  onRender: () =>
    @_toolbar ?= new MediumEditor @target_el,
      placeholder: false
      autoLink: true
      imageDragging: false
      anchor:
        customClassOption: null
        customClassOptionText: 'Button'
        linkValidation: false
        placeholderText: 'URL...'
        targetCheckbox: false
      anchorPreview: false
      extensions:
        footnote: new MediumEditorFootnote
           name: 'footnote'
           aria: 'footnote'
           contentDefault: '<svg><use xlink:href="#footnote_button"></use></svg>'
      paste:
        forcePlainText: false
        cleanPastedHTML: true
        cleanReplacements: []
        cleanAttrs: ['class', 'style', 'dir']
        cleanTags: ['meta']
      toolbar:
        updateOnEmptySelection: true
        allowMultiParagraphSelection: true
        buttons: @buttons


class Cms.Views.Toolbar extends Cms.Views.BaseToolbar
  template: ""
  className: "ed-toolbar"
  buttons: [
    name: 'bold'
    contentDefault: '<svg><use xlink:href="#bold_button"></use></svg>'
  ,
    name: 'italic'
    contentDefault: '<svg><use xlink:href="#italic_button"></use></svg>'
  ,
    name: 'anchor'
    contentDefault: '<svg><use xlink:href="#anchor_button"></use></svg>'
  ,
    name: 'removeFormat'
    contentDefault: '<svg><use xlink:href="#clear_button"></use></svg>'
  ]


class Cms.Views.BlocksToolbar extends Cms.Views.BaseToolbar
  template: ""
  className: "ed-toolbar"
  buttons: [
    name: 'bold'
    contentDefault: '<svg><use xlink:href="#bold_button"></use></svg>'
  ,
    name: 'italic'
    contentDefault: '<svg><use xlink:href="#italic_button"></use></svg>'
  ,
    name: 'anchor'
    contentDefault: '<svg><use xlink:href="#anchor_button"></use></svg>'
  ,
    name: 'footnote'
    contentDefault: '<svg><use xlink:href="#footnote_button"></use></svg>'
  ,
    name: 'orderedlist'
    contentDefault: '<svg><use xlink:href="#ol_button"></use></svg>'
  ,
    name: 'unorderedlist'
    contentDefault: '<svg><use xlink:href="#ul_button"></use></svg>'
  ,
    name: 'h2'
    contentDefault: '<svg><use xlink:href="#h1_button"></use></svg>'
  ,
    name: 'h3'
    contentDefault: '<svg><use xlink:href="#h2_button"></use></svg>'
  ,
    name: 'removeFormat'
    contentDefault: '<svg><use xlink:href="#clear_button"></use></svg>'
  ]


