import jester, karax/[karaxdsl, vdom]
import kform



func wrap(pageTitle: string, page: VNode): VNode =
  const cssFiles = @[
    "https://bootswatch.com/5/litera/bootstrap.min.css",
    "https://use.fontawesome.com/releases/v5.7.0/css/all.css",
    "/assets/custom.css"]

  buildHtml:
    html:
      head:
        meta(charset = "UTF-8")
        meta(http-equiv = "X-UA-Compatible", content = "IE=edge")
        meta(name = "viewport", content = "width=device-width, initial-scale=1.0")

        title:
          text pageTitle

        link(rel = "icon", type = "image/x-icon", href = "/assets/icon.png")
        script(src = "/assets/page.js", `defer` = "true")

        for path in cssFiles:
          link(rel = "stylesheet", href = path)

      body:
        tdiv(class = "container"):
          header(class = "mb-4")

          page

func wrapForm*(action: string, child: VNode): VNode =
  buildHtml form(`method` = "POST", action = action):
    child


let
  loginForm = kform ():
    uname as "user name": input string
    pass as "password": input Password
    submit "login"

  airCompanyForm = kform ():
    name: input string
    submit "add"

  airPlaneForm = kform (aircompany_id: int):
    model: input string
    capacity: input Positive
    company: hidden int = aircompany_id
    submit "add"

  travelForm = kform (aircompany_id, airplane_id: int):
    company: hidden int = aircompany_id
    airplane: hidden int = airplane_id
    pilot: input string
    destination: input string
    submit "add"

  buyTicketForm = kform (airplane_id: int, options: seq[int]):
    seat: select int = options
    icode as "international code": input string
    airplane: hidden int = airplane_id
    submit "buy"


when isMainModule:
  discard