import std/[times, strformat]
import karax/[karaxdsl, vdom]
import dbm, ui, dict


func navItem(name, iconClass, link: string): VNode =
  buildHtml:
    li(class = "nav-item"):
      a(class = "nav-link", href = link):
        text name
        span(class = "mx-1")
        icon iconClass

func page*(title: string, isAdmin: bool, page: VNode): VNode =
  const cssFiles = @[
    "https://bootswatch.com/5/litera/bootstrap.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"]

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
                  navItem "companies", "building", "/companies"
                  navItem "transactions", "credit-card", "/transactions"
                  navItem "Logout", "sign-out", "/logout"
                else:
                  navItem "Login", "right-to-bracket", "/login"


        tdiv(class = "container"):
          header(class = "mb-4"):
            discard

          page

func wrapForm*(action: string, child: VNode, `method` = "POST"): VNode =
  buildHtml form(`method` = `method`, action = action):
    child


func flysTable*(tks: seq[auto]): VNode =
  buildHtml:
    table(class = "table table-hover text-center"):
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

func transactionsView*(trs: seq[auto]): VNode =
  buildHtml table(class = "table table-hover text-center"):
    thead:
      for (name, iconClass) in [
        (Tid, "hashtag"),
        (TInternationalCode, "id-card"),
        (Tfly, "plane"),
        (Ttime, "clock"),
      ]:
        th:
          text name
          span(class = "mx-1")
          icon iconClass

      for t in trs:
        tr:
          td:
            text $t.id
          td:
            text $t.internationalCode
          td:
            a(href = fmt"/fly/{t.fly_id}", class = ""):
              text $t.fly_id
          td:
            text $t.timestamp

func ticketBuyReportPage*(
  purchaseId, icode: ID,
  origin, destination, pilot, company: string,
  cost: int
  ): VNode =

  buildHtml tdiv:
    table(class = "table table-hover"):
      tr: td: definitation TInternationalCode, $icode, "id-card"
      tr: td: definitation TCost, $cost, "money-bill"
      tr: td: definitation TOrigin, origin, "map-marker-alt"
      tr: td: definitation TDest, destination, "map-marked"
      tr: td: definitation TCompany, company, "building"
      tr: td: definitation TPilot, pilot, "user"

    a(href = "#", class = "btn btn-outline-primary w-100"):
      text "print "
      icon "print"

func companiesPage*(acs: seq[Company], isAdmin: bool): VNode =
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
          a(href = fmt"/companies/{ac.id}",
              class = "text-decoration-none"):
            text ac.name

          span:
            if isAdmin:
              a(href = fmt"/companies/{ac.id}/edit",
                  class = "btn btn-outline-warning"):
                text "edit"
                span(class = "mx-1")
                icon "pen"

              a(href = fmt"/companies/{ac.id}/delete",
                  class = "btn btn-outline-danger"):
                text "delete"
                span(class = "mx-1")
                icon "trash"

