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
        span(class="mx-1")
        text property
      span:
        text value
