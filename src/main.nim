import std/[os]
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

    post "/login":
      let t = parseForm loginForm
      # resp t.uname
      redirect "/companies"

    get "/companies":
      resp $page("comapnies", companiesPage getAllAirCompanies())

    get "/add-company":
      resp $page("index", wrapForm("", airCompanyForm.toVNode(-1, "")))

    post "/add-company":
      discard addCompany airCompanyForm.parseForm.name
      redirect "/companies"
