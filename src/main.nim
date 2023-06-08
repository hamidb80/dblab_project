import std/[os, tables, oids, times, strutils, strformat, sequtils, db_sqlite]
import jester, karax/[vdom]
import dbm, forms, pages, kform, ui, utils


template parseForm(form): untyped {.dirty.} =
  fromForm[form.data.type](request.params)

template isAdmin: untyped {.dirty.} =
  request.cookies.getOrDefault("AUTH").isAuthenticated

when isMainModule:
  initDB()

  routes:
    get "/assets/@path":
      let s = getCurrentDir() / "assets" / @"path"
      sendfile s


    get "/":
      let
        a = isAdmin
        q = request.params
        o = toOptionalInt(q.getOrDefault("origin_city") or "", "-1")
        d = toOptionalInt(q.getOrDefault("dest_city") or "", "-1")

      resp $page("tickets", a,
        verticalGroup(2,
          wrapForm("/", searchFlyForm.toVNode(
            @[(-1.int64, "-")] & getCities(),
            iff(isSome o, o.get, -1),
            iff(isSome d, d.get, -1),
        ), "GET"),
        iff(a, linkedBtn("/fly/add", "success w-100", namedIcon("add fly",
            "plane")), text ""),
        flysTable(getFlys(o, d, onlyFuture = true), a, {ftBuy})))

    get "/login":
      resp $page("login", isAdmin, wrapForm("/login", loginForm.toVNode()))

    get "/logout":
      if isAdmin:
        removeCookieFor request.cookies.getOrDefault("AUTH")

      redirect "/"

    post "/login":
      echo allAdmins()

      let t = parseForm loginForm
      if isAdmin(t.uname, t.pass):
        let ck = $genOid()
        addCookieFor(ck, t.uname)
        setCookie "AUTH", ck, now() + initDuration(hours = 1)
        redirect "/"
      else:
        resp "invalid auth"


    get "/transactions":
      resp $page("transactions", isAdmin, transactionsView getTransactions())

    get "/fly/@id/buy":
      let
        fid = parseInt @"id"
        options = (getAvailableSeats fid).mapIt (it[0], it[1])
      resp $page("comapnies", isAdmin, wrapForm("", buyTicketForm.toVNode(fid, options)))

    post "/fly/@id/buy":
      let form = parseForm buyTicketForm

      try:
        let pid = registerTicket(form.ticket_id, form.icode.parseInt)
        redirect "/purchase/" & $pid

      except DbError:
        resp "Error in DB"

      except ValueError:
        resp "form error: " & getCurrentExceptionMsg()

    get "/purchase/@id":
      let
        pid = parseint @"id"
        iii = getPurchaseFullInfo pid

      resp $page("ticket report", isAdmin, ticketBuyReportPage(
        pid,
        iii.purchase.international_code, iii.fly.takeoff,
        iii.fly.origin, iii.fly.dest, iii.fly.pilot, iii.fly.companyName,
        0))


    get "/fly/add":
      let
        cities = @[(-1.int64, "-")] & getCities()
        companies = @[(-1.int64, "-")] & (getAllAirCompanies().mapIt (it.id, it.name))

      resp $page("add fly", isAdmin, wrapForm("",
      addFlyFrom.toVnode(cities, companies, now(), 100, 10, "", -1, -1, -1)))

      resp "OK"

    post "/fly/add":
      let form = parseForm addFlyFrom
      let id = addFly(form.company_id, form.pilot, form.origin_city,
          form.dest_city, form.time, form.cost, form.capacity)
      redirect "/fly/" & $id

    get "/fly/@id":
      let
        id = parseInt @"id"
        f = getFlys(flyid = some id)[0]

      resp $page("fly info", isAdmin, flyInfo f)

    get "/fly/@id/cancell":
      let id = parseint @"id"
      cancellFly id
      resp fmt"fly {id} cancelled"


    get "/companies":
      let a = isAdmin
      resp $page("comapnies", a, companiesListPage(getAllAirCompanies(), a))

    get "/companies/add":
      resp $page("index", isAdmin, wrapForm("", airCompanyForm.toVNode(-1, "")))

    post "/companies/add":
      discard addCompany airCompanyForm.parseForm.name
      redirect "/companies"

    get "/companies/@id/edit":
      let
        id = parseint @"id"
        c = getCompany id
      resp $page("index", isAdmin, wrapForm("", airCompanyForm.toVNode(id, c.name)))

    post "/companies/@id/edit":
      let form = parseForm airCompanyForm

      updateCompany form.id, form.name
      redirect "/companies"

    get "/companies/@id/delete":
      deleteCompany parseInt @"id"
      redirect "/companies"

    get "/companies/@id":
      let
        id = parseint @"id"
        c = getCompany id
        a = isAdmin

      resp $page("company", a, verticalGroup(2,
        titleHead(1, c.name, "building"),
        flysTable(getflys(company_id = some id), a, {ftCompanyPage})))


    # get "/companies/@id/planes":
    #   discard

    # get "/companies/@id/planes/add":
    #   discard

    # post "/companies/@id/planes/add":
    #   discard

    # get "/companies/@cid/planes/@pid/deprecate":
    #   discard


    get "/ports":
      resp $page("ports", isAdmin, portsView allPorts())

    get "/ports/add":
      let cc = @[(-1.int64, "-")] & getCities()
      resp $page("add port", isAdmin,
        wrapForm("", addPortForm.toVnode(cc, -1, -1, "")))

    post "/ports/add":
      let
        form = parseForm addPortForm
        id = addPort(form.city_id, form.name)

      redirect "/ports"

    # get "/ports/@id/delete":
    #   discard
