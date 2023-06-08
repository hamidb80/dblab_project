import std/[times]
import kform
import karax/[karaxdsl, vdom]

type
  City = tuple
    id: ID
    loc: string

  Company = tuple
    id: ID
    name: string


let
  airCompanyForm* = kform (id: ID, cname: string):
    id as "id": hidden ID = id
    name as "name": input string = cname {.icon: "font".}
    submit "add"

  buyTicketForm* = kform (fly_id: ID, options: seq[(ID, int)]):
    ticket_id as "seat number": select[options]ID = options[0][0]
    icode as "international code": input string = ""
    fly_id as "": hidden ID = fly_id
    submit "buy" {.icon: "credit-card".}

  loginForm* = kform ():
    uname as "user name": input string = "" {.icon: "user".}
    pass as "password": input Secret = "" {.icon: "lock".}
    submit "login" {.icon: "certificate".}

  searchFlyForm* = kform (cities: seq[City]):
    origin_city as "origin": select[cities]ID = 0 {.icon: "map-marker-alt".}
    dest_city as "destination": select[cities]ID = 0 {.icon: "map-marked".}
    submit "search" {.icon: "magnifying-glass".}

  addFlyFrom* = kform (cities: seq[City], companies: seq[Company],
      time: DateTime, cost: Natural, capacity: Natural, pilot: string,
      origin_city_id: ID,dest_city_id: ID, company_id: ID,
      ):

    company_id as "origin": select[companies]ID = 0 {.icon: "building".}
    origin_city as "origin": select[cities]ID = 0 {.icon: "map-marker-alt".}
    dest_city as "destination": select[cities]ID = 0 {.icon: "map-marked".}
    time as "time": input DateTime = time {.icon: "clock".}
    cost as "cost": input Natural = cost {.icon: "money".}
    capacity as "capacity": input Natural = capacity {.icon: "users".}
    pilot as "pilot": input string = pilot {.icon: "person-military-pointing".}
    submit "add" {.icon: "plus".}
