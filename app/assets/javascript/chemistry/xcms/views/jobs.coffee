class Cms.Views.Job extends Cms.View
  template: "helpers/job"
  tagName: "li"
  className: "job"

  bindings:
    ":el":
      classes:
        finished: "completed"
        failed: "failed"
    "span.job_status": "status"
    "span.percentage": "progress"
    "span.error":
      observe: "error"
      visible: true
      visibleFn: "visibleAsBlock"
      updateVew: true
    "span.bar":
      attributes: [
        name: "style"
        observe: "progress"
        onGet: "styleWidth"
      ]

  styleWidth: (progress) =>
    "width: #{progress}%"

  remove: =>
    @$el.fadeOut "slow", =>
      @$el.remove()


class Cms.Views.JobQueue extends Cms.CollectionView
  childView: Cms.Views.Job
  tagName: "ul"
  className: "jobs"
