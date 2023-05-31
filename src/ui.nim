import karax/[karaxdsl, vdom]

func icon*(name: string, themed = true): Vnode =
  buildHTML bold(class = (if themed: "text-primary " else: "") & "fa fa-" & name)

func label2*(text, iconName: string): VNode =
  buildHTML:
    tdiv(class = "d-flex justify-content-between align-items-center"):
      label:
        text `text`
      icon `iconName`
