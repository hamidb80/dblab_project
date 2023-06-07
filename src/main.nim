import std/[os, tables, oids, times, strutils, sequtils, db_sqlite]
import jester, karax/[vdom]
import dbm, forms, pages, kform


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
      resp $page("tickets", isAdmin, flysTable(getActiveFlys(none int, none int)))

    get "/login":
      resp $page("login", isAdmin, wrapForm("/login", loginForm.toVNode()))

    get "/logout":
      if isAdmin:
        resp "Good"
      else:
        resp "No"

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


    get "/fly/@id/buy":
      let
        fid = parseint @"id"
        options = (getAvailableSeats fid).mapIt (it[0].int, it[1])
      resp $page("comapnies", isAdmin, wrapForm("", buyTicketForm.toVNode(fid, options)))

    post "/fly/@id/buy":
      let form = parseForm buyTicketForm

      try:
        let purchaseId = registerTicket(form.ticket_id, form.icode.parseInt)
        resp $page("ticket report", isAdmin, ticketBuyReportPage(
          purchaseId,
          form.icode.parseInt,
          "tehran", "iran", "ali", "air",
          10))

      except DbError:
        resp "Error in DB"

      except ValueError:
        resp "form error: " & getCurrentExceptionMsg()


    get "/fly/add":
      resp "OK"

    post "/fly/add":
      resp "OK"

    get "/fly/@id/cancell":
      resp "OK"


    get "/companies":
      resp $page("comapnies", isAdmin, companiesPage getAllAirCompanies())

    get "/companies/@id/report":
      # origin dest time travelers/capacity cancelled
      resp "OK"

    get "/companies/add":
      resp $page("index", isAdmin, wrapForm("", airCompanyForm.toVNode(-1, "")))

    post "/companies/add":
      discard addCompany airCompanyForm.parseForm.name
      redirect "/companies"

    get "/companies/@id/edit":
      let 
        id =  parseint @"id"
        c = getCompany id
      resp $page("index", isAdmin, wrapForm("", airCompanyForm.toVNode(id, c.name)))
    
    post "/companies/@id/edit":
      let form = parseForm airCompanyForm
      
      updateCompany form.id, form.name
      redirect "/companies"

    get "/companies/@id/delete":
      deleteCompany parseInt @"id"
      redirect "/companies"
