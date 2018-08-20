class Cms.Models.Enquiry extends Cms.Model
  savedAttributes: ['name', 'email', 'message', 'closed', 'robot']
  uploadProgress: false

  completed: (e) =>
    @save
      closed: true


class Cms.Collections.Enquiries extends Cms.Collection
  model: Cms.Models.Enquiry
