class Cms.Models.Image extends Cms.Model
  savedAttributes: ["title", "caption", "file_data", "file_name", "remote_url"]

  initialize: () ->
    super
    @on 'change:file_data', @getThumbs

  getThumbs: (data) =>
    img = document.createElement('img')
    w = 48
    img.onload = =>
      thumb_url = @resizeImage(img, 48)
      @set "thumb_url", thumb_url
      full_url = @resizeImage(img, 1120)
      @set "file_url", full_url
    img.src = @get('file_data')

  resizeImage: (img, w=48) =>
    unless @get('url')
      if img.height > img.width
        h = w * (img.height / img.width)
      else
        h = w
        w = h * (img.width / img.height)
      canvas = document.createElement('canvas')
      canvas.width = w
      canvas.height = h
      ctx = canvas.getContext('2d')
      ctx.drawImage(img, 0, 0, w, h)
      preview = canvas.toDataURL('image/png')


class Cms.Collections.Images extends Cms.Collection
  model: Cms.Models.Image
