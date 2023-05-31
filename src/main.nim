import std/[os, tables, oids, times]
import jester, karax/[vdom]
import dbm, forms, pages, kform


template parseForm(form): untyped {.dirty.} =
  fromForm[form.data.type](request.params)

when isMainModule:
  initDB()

  routes:
    get "/assets/@path":
      let s = getCurrentDir() / "assets" / @"path"
      echo s
      sendfile s

    get "/":
      resp $page("tickets", flysTable(getActiveFlys()))

    get "/login":
      resp $page("login", wrapForm("/login", loginForm.toVNode()))

    get "/logout":
      if request.cookies.getOrDefault("AUTH").isAuthenticated:
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

    # get "/me":


    get "/companies":
      resp $page("comapnies", companiesPage getAllAirCompanies())

    get "/add-company":
      resp $page("index", wrapForm("", airCompanyForm.toVNode(-1, "")))

    post "/add-company":
      discard addCompany airCompanyForm.parseForm.name
      redirect "/companies"
