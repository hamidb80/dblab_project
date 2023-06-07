import std/[times, strformat]
import karax/[karaxdsl, vdom]
import dbm, ui, dict


func navItem(name, link: string): VNode =
  buildHtml:
    li(class = "nav-item"):
      a(class = "nav-link", href = link):
        text name

func page*(title: string, isAdmin: bool, page: VNode): VNode =
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
                if isAdmin:
                  navItem "Logout", "/logout"
                  navItem "companies", "/companies"
                else:
                  navItem "Login", "/login"

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
          for (name, iconClass) in [
            ("مبدا", "map-marker-alt"),
            ("مقصد", "map-marked"),
            ("شرکت", "building"),
            ("پرواز", "plane-departure"),
            ("باقی مانده", "user-friends"),
            ("خرید", "money-bill"),
            ]:
            th(scope = "col"):
              text name
              span(class = "m-1")
              icon iconClass

      tbody(class = "text-center"):
        for i, t in tks:
          tr(class = (if i mod 2 == 0: "table-active" else: "")):
            td: text t.origin
            td: text t.dest
            td: text t.company
            td: text $t.takeoff
            td: text $t.left
            td:
              a(class = "btn btn-success", href = fmt"/fly/{t.id}/buy"):
                icon"money-bill"

func ticketsPage*(tks: seq[Ticket]): VNode =
  buildHtml tdiv()

func ticketBuyReportPage*(
  purchaseId, icode: ID,
  origin, destination, pilot, company: string,
  cost: int
  ): VNode =

  buildHtml tdiv():
    definitation TPilot, pilot, "user"
    definitation TInternationalCode, $icode, "user"
    definitation TCost, $cost, "money-bill"
    definitation TOrigin, origin, "money-bill"
    definitation TDest, destination, "money-bill"
    definitation TCompany, company, "building"

func companiesPage*(acs: seq[Company]): VNode =
  buildHtml tdiv:
    h3:
      text "companies"

    a(href = "/companies/add", class = "btn btn-outline-success my-2 w-100"):
      text "add"
      span(class = "mx-1")
      icon "plus"

    for ac in acs:
      ul(class = "list-group"):
        li(class = "list-group-item d-flex justify-content-between align-items-center"):
          a(href=fmt"/companies/{ac.id}/report", class="text-decoration-none"):
            text ac.name

          span:
            a(href = fmt"/companies/{ac.id}/edit", class = "btn btn-outline-warning"):
              text "edit"
              span(class = "mx-1")
              icon "pen"

            a(href = fmt"/companies/{ac.id}/delete", class = "btn btn-outline-danger"):
              text "delete"
              span(class = "mx-1")
              icon "trash"

