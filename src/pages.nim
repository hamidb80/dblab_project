import std/[times, strformat]
import karax/[karaxdsl, vdom]
import dbm, ui, dict, utils


func navItem(name, iconClass, link: string): VNode =
  buildHtml:
    li(class = "nav-item"):
      a(class = "nav-link", href = link):
        namedIcon name, iconClass

func page*(title: string, isAdmin: bool, page: VNode): VNode =
  const cssFiles = @[
    "https://bootswatch.com/5/litera/bootstrap.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css",
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
        script(src = "/assets/script.js", `defer` = "true")

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
                  navItem "ports", "city", "/ports"
                  navItem "locations", "location-dot", "/locations"
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


type
  FlyTableOptions* = enum
    ftBuy
    ftCompanyPage

func thFlyc(name, iconClass: string): VNode =
  buildHtml th(scope = "col"):
    text name
    span(class = "m-1")
    icon iconClass

func flysTable*(tks: seq[auto], isAdmin: bool, options: set[
    FlyTableOptions]): VNode =
  buildHtml:
    table(class = "table table-hover text-center rtl"):
      thead:
        tr:
          thFlyc "مبدا", "map-marker-alt"
          thFlyc "مقصد", "map-marked"
          thFlyc "پرواز", "clock"

          if ftCompanyPage in options:
            thFlyc "ظرفیت", "user-friends"
            thFlyc "پرشده", "user-friends"
          else:
            thFlyc "شرکت", "building"
            thFlyc "باقی مانده", "user-friends"

          if ftBuy in options:
            thFlyc "خرید", "money-bill"

          if isAdmin:
            thFlyc "کنسل", "ban"


      tbody:
        for i, t in tks:
          tr(class = (if i mod 2 == 0: "table-active" else: "")):
            td: text t.origin
            td: text t.dest
            td: text $t.takeoff

            if ftCompanyPage in options:
              td: text $t.capacity
              td: text $t.used
            else:
              td:
                a(href = "/companies/" & $t.company_id,
                    class = "text-decoration-none"):
                  text t.companyName
              td: text $(t.capacity - t.used)

            if ftBuy in options:
              td:
                a(class = "btn btn-success", href = fmt"/fly/{t.id}/buy"):
                  icon"money-bill"

            if isAdmin:
              td:
                a(class = "btn btn-warning " & iff(t.cancelled, "disabled", ""),
                    href = fmt"/fly/{t.id}/cancell"):
                  icon"ban"


func transactionsView*(trs: seq[auto]): VNode =
  buildHtml table(class = "table table-hover text-center rtl"):
    thead:
      for (name, iconClass) in [
        (Tid, "hashtag"),
        (TInternationalCode, "id-card"),
        (Tfly, "plane"),
        (Ttime, "clock"),
      ]:
        th:
          namedIcon name, iconClass

      for t in trs:
        tr:
          td:
            a(href = "/purchase/" & $t.id, class = "text-decoration-none"):
              text $t.id
          td:
            text $t.internationalCode
          td:
            a(href = fmt"/fly/{t.fly_id}", class = "text-decoration-none"):
              text $t.fly_id
          td:
            text $t.timestamp

func printBtn*: VNode =
  buildHtml button(class = "btn btn-outline-primary w-100"):
    text "print "
    icon "print"

func flyInfo*(finfo: auto): VNode =
  buildHtml tdiv:
    table(class = "table table-hover"):
      tr: td: definitation TOrigin, finfo.origin & " :: " & finfo.originPort, "map-marker-alt"
      tr: td: definitation TDest, finfo.dest & " :: " & finfo.destPort, "map-marked"
      tr: td: definitation TCompany, finfo.companyName, "building"
      tr: td: definitation TDate, finfo.takeoff, "user"
      tr: td: definitation TPilot, finfo.pilot, "clock"
      tr: td: definitation TCapacity, $finfo.capacity, "users"
      tr: td: definitation TPassenger, $finfo.used, "users"
      tr: td: definitation TIsCancelled, finfo.cancelled.toFa, "ban"


func ticketBuyInfo*(purchaseId, icode: ID,
  timestamp: DateTime, seat: Natural,
  ): VNode =

  buildHtml table(class = "table table-hover"):
    tr: td: definitation Tid, $purchaseId, "hashtag"
    tr: td: definitation Ttime, $timestamp, "clock"
    tr: td: definitation TInternationalCode, $icode, "id-card"
    tr: td: definitation TSeatNumber, $seat, "couch"

func companiesListPage*(acs: seq[Company], isAdmin: bool): VNode =
  buildHtml tdiv:
    h3: text "companies"

    linkedBtn("/companies/add", "success my-2 w-100", namedIcon("add", "plus"))

    for ac in acs:
      ul(class = "list-group"):
        li(class = "list-group-item d-flex justify-content-between align-items-center"):
          a(href = fmt"/companies/{ac.id}", class = "text-decoration-none"):
            text ac.name

          span:
            if isAdmin:
              linkedBtn(fmt"/companies/{ac.id}/edit", "outline-warning rtl",
                namedIcon("edit", "pen"))

              linkedBtn(fmt"/companies/{ac.id}/delete", "outline-danger rtl",
                namedIcon("delete", "trash"))

func portsView*(ports: seq[auto]): VNode =
  buildHtml tdiv:
    a(href = "/ports/add", class = "btn btn-success w-100 my-2"):
      namedIcon "add ", "hashtag"

    table(class = "table text-center rtl"):
      thead:
        td: namedIcon "شناسه", "hashtag"
        td: namedIcon "نام", "font"
        td: namedIcon "شهر", "city"

      tbody:
        for p in ports:
          tr:
            td: text $p.id
            td: text p.name
            td: text p.location

func locationsTable*(locations: seq[auto]): VNode =
  buildHtml tdiv:
    h3:
      namedIcon "Locations", "cities"

    linkedBtn("/locations/add", "success w-100 my-2",
      namedIcon("add", "plus"))

    table(class = "table table-hover text-center"):
      thead:
        tr:
          th: namedIcon "country", "globe"
          th: namedIcon "city", "map-location-dot"

      tbody:
        for l in locations:
          tr:
            td: text l.country
            td: text l.city
