import std/[times]
import ponairi


type
  AirCompany* = object
    id* {.primary, autoIncrement.}: int
    name*: string

  AirPlane* = object
    id* {.primary, autoIncrement.}: int
    company* {.references: Company.id.}: int
    model*: string
    capacity*: Positive

  Travel* = object
    id* {.primary, autoIncrement.}: int
    airplane* {.references: AirPlane.id.}: int
    pilot*: string
    destination*: string
    takeoff*: DateTime

  Ticket* = object
    id* {.primary, autoIncrement.}: int
    travel* {.references: TravelAirPlane.id.}: int
    seat*: Positive


const dbPath {.strdefine.} = "db.sqlite3"

template db*: untyped =
  open(dbPath, "", "", "")

proc initDB* =
  db.create(AirCompany, AirPlane, Travel, Ticket)

proc getAllAirCompanies*: auto =
  db.find(seq[AirCompany])
