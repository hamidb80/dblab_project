import std/[times]
import ponairi


type
  Country* = object
    id* {.primary, autoIncrement.}: int64
    name* {.uniqueIndex.}: string

  City* = object
    id* {.primary, autoIncrement.}: int64
    country_id* {.references: Country.id.}: int64
    name*: string

  Airport* = object
    id* {.primary, autoIncrement.}: int64
    city_id* {.references: City.id.}: int64
    name* {.uniqueIndex.}: string

  Company* = object
    id* {.primary, autoIncrement.}: int64
    name* {.uniqueIndex.}: string

  Airplane* = object
    id* {.primary, autoIncrement.}: int64
    company_id* {.references: Company.id.}: int64
    model*: string
    capacity*: Positive

  Fly* = object
    id* {.primary, autoIncrement.}: int64
    airplane_id* {.references: Airplane.id.}: int64
    pilot*: string
    destination_id* {.references: Airport.id.}: int64
    takeoff*: DateTime

  Ticket* = object
    id* {.primary, autoIncrement.}: int64
    fly_id* {.references: Fly.id.}: int64
    seat*: Positive

# ---

const dbPath {.strdefine.} = "db.sqlite3"

template db*: untyped =
  ponairi.open(dbPath, "", "", "")

proc initDB* =
  db.create(Country, City, Airport, Company, Airplane, Fly, Ticket)

# ---

proc addCountry*(name: string): int64 =
  db.insertID Country(name: name)

proc addCity*(country: int64, name: string): int64 =
  db.insertID City(country_id: country, name: name)

proc addAirport*(city: int64, name: string): int64 =
  db.insertID Airport(city_id: city, name: name)

proc addCompany*(name: string): int64 =
  db.insertID Company(name: name)

proc addAirplane*(model: string, cap: int, company: int64): int64 =
  db.insertID Airplane(model: model, company_id: company, capacity: cap)


proc getAllAirCompanies*: auto =
  db.find(seq[Company])

proc getActiveTickets*: auto = 
  db.find(seq[tuple[airport, city, country, company: string]], sql"""
    SELECT p.name, ct.name, cn.name, cp.name
    FROM Fly f
    
    JOIN Airport p
    ON p.id = f.destination_id

    JOIN City ct
    ON p.city_id = ct.id

    JOIN Country cn
    ON cn.id = ct.country_id

    JOIN Airplane ap
    ON ap.id = f.airplane_id

    JOIN Company cp
    ON ap.company_id = cp.id

    -- WHERE timediff(f.takeoff, now()) < hours(1)
  """)