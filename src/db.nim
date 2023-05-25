import std/[times]
import ponairi


type
  AirCompany = object
    id {.primary, autoIncrement.}: int
    name: string

  AirPlane = object
    id {.primary, autoIncrement.}: int
    company {.references: Company.id.}: int
    model: string
    capacity: Positive

  Travel = object
    id {.primary, autoIncrement.}: int
    airplane {.references: AirPlane.id.}: int
    pilot: string
    destination: string
    takeoff: DateTime

  Ticket = object
    id {.primary, autoIncrement.}: int
    travel {.references: TravelAirPlane.id.}: int
    seat: Positive
