import std/times
import karax/[karaxdsl, vdom]
import dbm


func page*(title: string, page: VNode): VNode =
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

        link(rel = "icon", type = "image/x-icon", href = "/assets/travel.svg")
        # script(src = "/assets/page.js", `defer` = "true")

        for path in cssFiles:
          link(rel = "stylesheet", href = path)

      body:
        nav(class = "navbar navbar-expand-lg navbar-light bg-light"):
          tdiv(class = "container-fluid"):
            a(class = "navbar-brand", href = "/"):
              text "Travelll.ir"

            tdiv(class = "collapse navbar-collapse"):
              ul(class = "navbar-nav me-auto"):

                li(class = "nav-item"):
                  a(class = "nav-link", href = "/login"):
                    # TODO
                    text "Login"

                li(class = "nav-item"):
                  a(class = "nav-link active", href = "/companies"):
                    text "my tickets"

                li(class = "nav-item"):
                  a(class = "nav-link active", href = "/companies"):
                    text "companies"

        tdiv(class = "container"):
          header(class = "mb-4"):
            discard

          page

func wrapForm*(action: string, child: VNode, `method` = "POST"): VNode =
  buildHtml form(`method` = `method`, action = action):
    child

func flysTable*(tks: seq[auto]): VNode =
  buildHtml:
    table(class = "table table-hover"):
      thead:
        tr:
          for name in ["مبدا", "مقصد", "شرکت", "پرواز",
              "باقی مانده"]:
            th(scope = "col"):
              text name

      tbody:
        for i, t in tks:
          tr(class = (if i mod 2 == 0: "table-active" else: "")):
            td: text t.origin
            td: text t.dest
            td: text t.company
            td: text $t.takeoff
            td: text $t.left

func ticketsPage*(tks: seq[Ticket]): VNode =
  buildHtml tdiv()

func buyTicket*(): VNode =
  buildHtml tdiv()

func companiesPage*(acs: seq[Company]): VNode =
  buildHtml tdiv:
    h3:
      text "companies"

    for ac in acs:
      ul(class = "list-group"):
        li(class = "list-group-item d-flex justify-content-between align-items-center"):
          span:
            text ac.name

          span(class = "badge bg-primary rounded-pill"):
            text "14"
