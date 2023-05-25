import std/[json, strtabs, times]
import jester, karax/[karaxdsl, vdom]
import kform, db


func page(title: string, page: VNode): VNode =
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
          text title

        link(rel = "icon", type = "image/x-icon", href = "/assets/icon.png")
        # script(src = "/assets/page.js", `defer` = "true")

        for path in cssFiles:
          link(rel = "stylesheet", href = path)

      body:
        tdiv(class = "container"):
          header(class = "mb-4")

          page

func wrapForm*(action: string, child: VNode, `method` = "POST"): VNode =
  buildHtml form(`method` = `method`, action = action):
    child



let
  loginForm = kform ():
    uname as "user name": input string = "" {.icon: "user".}
    pass as "password": input Secret = "" {.icon: "lock".}
    submit "login" {.icon: "certificate".}

  airCompanyForm = kform (id: int, cname: string):
    id as "id": hidden int = id
    name as "name": input string = cname {.icon: "font".}
    submit "add"

  airPlaneForm = kform (aircompany_id: int, cap: int):
    model as "model": input string = "" {.icon: "plane".}
    cap as "capacity": input int = cap {.icon: "users".}
    company as "company": hidden int = aircompany_id
    submit "add"

  travelForm = kform (aircompany_id: int, airplane_id: int):
    company as "company": hidden int = aircompany_id
    airplane as "airplane": hidden int = airplane_id
    pilot as "pilot": input string = "" {.icon: "fa-graduation-cap".}
    takeoff as "take off time": input DateTime = "" {.icon: "clock-o".}
    destination as "destination": input string = "" {.icon: "road".}
    submit "add" {.icon: "plus".}

  buyTicketForm = kform (airplane_id: int, options: seq[int]):
    seat as "seat number": select[options]int = options[0]
    icode as "international code": input string = ""
    airplane as "airplane": hidden int = airplane_id
    submit "buy" {.icon: "money".}


when isMainModule:
  echo loginForm.toVNode()
  echo airCompanyForm.toVNode(1, "ww")
  echo airPlaneForm.toVNode(1, 10)
  echo travelForm.toVNode(10, 2)
  echo buyTicketForm.toVNode(10, @[1, 2, 3])


template parseForm(form): untyped {.dirty.} =
  fromForm[form.data.type](request.params)

func ticketsTable(): VNode =
  let tks = getTickets()

  buldHtml:
    table(class = "table table-hover"):
      thead:
        tr:
          th(scope = "col"):
            text "Type"
          th(scope = "col"):
            text "Column heading"

      tbody:
        for t in tks:
          tr(class = "table-active"):
            td:
              text "Column content"

            text "Morbi leo risus"
            text "dest: "
            text "bill: "
            text "time: "
            span(class = "badge bg-primary rounded-pill"):
              text "free"


func buyTicket(): VNode =
  buildHtml tdiv()


when isMainModule:
  initDB()

  routes:
    get "/":
      resp $page("tickets", ticketsPage())

    get "/login":
      resp $page("login", wrapForm("/login", loginForm.toVNode()))

    post "/login":
      let t = parseForm loginForm
      resp t.uname

    get "/companies":
      resp %*getAllAirCompanies()

    get "/add-company":
      resp $page("index", wrapForm("", airCompanyForm.toVNode(-1, "")))

    post "/add-company":
      resp %*request.params
