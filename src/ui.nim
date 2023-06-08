import karax/[karaxdsl, vdom]

func icon*(name: string): Vnode =
  buildHTML bold(class = "fa fa-" & name)

func customLabel*(content, iconName: string): VNode =
  buildHTML:
    tdiv(class = "d-flex justify-content-between align-items-center"):
      label:
        text content
      icon iconName

func definitation*(property, value, iconName: string): VNode =
  buildHTML:
    tdiv(class = "d-flex justify-content-between align-items-center"):
      span:
        icon iconName
        span(class = "mx-1"): text " "
        text property
      span:
        text value

func groupVertical*(space: range[1..6], vnodes: varargs[VNode]): VNode =
  buildHtml tdiv:
    for vn in vnodes:
      vn
      tdiv(class = "my-" & $space)
