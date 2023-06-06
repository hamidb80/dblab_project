import std/[times]
import kform
import karax/[karaxdsl, vdom]

let
  airCompanyForm* = kform (id: int, cname: string):
    id as "id": hidden int = id
    name as "name": input string = cname {.icon: "font".}
    submit "add"

  airPlaneForm* = kform (aircompany_id: int, cap: int):
    model as "model": input string = "" {.icon: "plane".}
    cap as "capacity": input int = cap {.icon: "users".}
    company as "company": hidden int = aircompany_id
    submit "add"

  travelForm* = kform (aircompany_id: int, airplane_id: int):
    company as "company": hidden int = aircompany_id
    airplane as "airplane": hidden int = airplane_id
    pilot as "pilot": input string = "" {.icon: "fa-graduation-cap".}
    takeoff as "take off time": input DateTime = "" {.icon: "clock-o".}
    destination as "destination": input string = "" {.icon: "road".}
    submit "add" {.icon: "plus".}

  buyTicketForm* = kform (fly_id: int, options: seq[(int, int)]):
    ticket_id as "seat number": select[options]int = options[0]
    icode as "international code": input string = ""
    fly_id as "": hidden int = fly_id
    submit "buy" {.icon: "credit-card".}

  loginForm* = kform ():
    uname as "user name": input string = "" {.icon: "user".}
    pass as "password": input Secret = "" {.icon: "lock".}
    submit "login" {.icon: "certificate".}
