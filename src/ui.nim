import karax/[karaxdsl, vdom]

func icon*(name: string): Vnode =
  buildHTML bold(class = "fa fa-" & name)

func emptyVnode*: VNode = text ""

func namedIcon*(name, iconClass: string): VNode =
  buildHtml span:
    text name
    text " "
    span(class = "mx-1")
    icon iconClass

func linkedBtn*(url, classes: string, inner: VNode): VNode =
  buildHtml a(href = url, class = "btn btn-" & classes):
    inner

func customLabel*(content, iconName: string): VNode =
  buildHTML:
    tdiv(class = "d-flex justify-content-between align-items-center"):
      label:
        text content
      icon iconName

func definitation*(property, value, iconName: string): VNode =
  buildHTML:
    tdiv(class = "d-flex justify-content-between align-items-center"):
      span(class = "rtl"):
        namedIcon property, iconName
      span:
        text value

func verticalGroup*(space: range[1..6], vnodes: varargs[VNode]): VNode =
  buildHtml tdiv:
    for vn in vnodes:
      vn
      tdiv(class = "my-" & $space)

func wrappedText(content: string): VNode =
  buildHtml span:
    text content

func titleHEad*(level: range[1..6], content, iconClass: string): VNode =
  result = buildHtml:
    case level
    of 1: h1()
    of 2: h2()
    of 3: h3()
    of 4: h4()
    of 5: h5()
    of 6: h6()

  result.add wrappedText content
  result.add icon iconClass


