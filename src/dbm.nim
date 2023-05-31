import std/[times, options]
import ponairi

type
  ID* = int64

  Country* = object
    id* {.primary, autoIncrement.}: ID
    name* {.uniqueIndex.}: string

  City* = object
    id* {.primary, autoIncrement.}: ID
    country_id* {.references: Country.id.}: ID
    name*: string

  Airport* = object
    id* {.primary, autoIncrement.}: ID
    city_id* {.references: City.id.}: ID
    name* {.uniqueIndex.}: string

  Company* = object
    id* {.primary, autoIncrement.}: ID
    name* {.uniqueIndex.}: string

  Airplane* = object
    id* {.primary, autoIncrement.}: ID
    company_id* {.references: Company.id.}: ID
    model*: string
    capacity*: Positive

  Fly* = object
    id* {.primary, autoIncrement.}: ID
    pilot*: string
    airplane_id* {.references: Airplane.id.}: ID
    origin_id* {.references: Airport.id.}: ID # TODO add in datagen
    destination_id* {.references: Airport.id.}: ID
    takeoff*: DateTime

  Ticket* = object
    id* {.primary, autoIncrement.}: ID
    fly_id* {.references: Fly.id.}: ID
    seat*: Positive
    reserved_by*: Option[int]

# ---

const dbPath {.strdefine.} = "db.sqlite3"

template db*: untyped =
  ponairi.open(dbPath, "", "", "")

proc initDB* =
  db.create(Country, City, Airport, Company, Airplane, Fly, Ticket)

# ---

proc addCountry*(name: string): ID =
  db.insertID Country(name: name)

proc addCity*(country: ID, name: string): ID =
  db.insertID City(country_id: country, name: name)

proc addAirport*(city: ID, name: string): ID =
  db.insertID Airport(city_id: city, name: name)

proc addCompany*(name: string): ID =
  db.insertID Company(name: name)

proc addAirplane*(model: string, cap: int, company: ID): ID =
  db.insertID Airplane(model: model, company_id: company, capacity: cap)

proc addFly*(aid: ID, pilot: string, dest: ID, t = now()): ID =
  result = db.insertID Fly(
    airplane_id: aid,
    pilot: pilot,
    destination_id: dest,
    takeoff: t)

  let ap = db.find(Airplane, sql"SELECT * FROM Airplane WHERE id = ?", aid)

  let s = db
  s.exec sql"BEGIN"
  
  for i in 1..ap.capacity:
    s.exec sql"INSERT INTO Ticket (fly_id, seat) VALUES (?, ?)", result, i

  s.exec sql"COMMIT"

  debugEcho "done ", result

proc getAllAirCompanies*: auto =
  db.find(seq[Company])

proc getActiveTickets*: auto =
  db.find(seq[tuple[id: int, airport, city, country, company, airplane: string, left: int]],
    sql"""
    SELECT f.id, p.name, ct.name, cn.name, cp.name, ap.model, COUNT(f.id)
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

    JOIN Ticket t
    ON 
      t.fly_id = f.id AND
      t.reserved_by IS NULL
    GROUP BY t.fly_id

    -- WHERE timediff(f.takeoff, now()) < hours(1)
  """)
