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

  addLocationForm* = kform ():
    country as "country": input string = "" {.icon: "globe".}
    city as "city": input string = "" {.icon: "map-location-dot".}
    submit "add" {.icon: "plus".}


  loginForm* = kform ():
    uname as "user name": input string = "" {.icon: "user".}
    pass as "password": input Secret = "" {.icon: "lock".}
    submit "login" {.icon: "certificate".}

  searchFlyForm* = kform (cities: seq[City], origin_city: ID, dest_city: ID):
    origin_city as "origin": select[cities]ID = origin_city {.icon: "map-marker-alt".}
    dest_city as "destination": select[cities]ID = dest_city {.icon: "map-marked".}
    submit "search" {.icon: "magnifying-glass".}

  addFlyFrom* = kform (ports: seq[City], companies: seq[Company],
      time: DateTime, cost: Natural, capacity: Natural, pilot: string,
      origin_city_id: ID, dest_city_id: ID, company_id: ID,
      ):

    company_id as "company": select[companies]ID = 0 {.icon: "building".}
    origin_city as "origin": select[ports]ID = 0 {.icon: "map-marker-alt".}
    dest_city as "destination": select[ports]ID = 0 {.icon: "map-marked".}
    time as "time": input DateTime = time {.icon: "clock".}
    cost as "cost": input Natural = cost {.icon: "money".}
    capacity as "capacity": input Natural = capacity {.icon: "users".}
    pilot as "pilot": input string = pilot {.icon: "person-military-pointing".}
    submit "add" {.icon: "plus".}

  addPortForm* = kform (cities: seq[City], city_id: ID, id: ID, name: string):
    id as "id": hidden int = city_id {.icon: "map-marker-alt".}
    city_id as "city": select[cities]ID = city_id {.icon: "map-marker-alt".}
    name as "name": input string = name {.icon: "font".}
    submit "add" {.icon: "plus".}
