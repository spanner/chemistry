class Cms.Views.Nav extends Cms.View
  template: "nav"

  ui:
    head: "a.menu"
    mask: "div.mask"
    nav: "nav.submenu"

  events:
    "click @ui.head": "toggleNav"
    "click @ui.nav": "hideNav"

  onRender: =>
    # nothing to do here

  toggleNav: =>
    if @ui.nav.hasClass('up')
      @hideNav()
    else
      @showNav()

  hideNav: =>
    @ui.nav.removeClass('up')

  showNav: =>
    @ui.nav.addClass('up')
