import std/[times, options, sha1, strformat, strutils]
import ponairi

type
  ID* = int64

  Admin* = object
    username* {.primary.}: string
    hashedPass*: string

  AuthCookie* = object
    cookie* {.primary, uniqueIndex.}: string
    username* {.references: Admin.username.}: string

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
    origin_id* {.references: Airport.id.}: ID
    destination_id* {.references: Airport.id.}: ID
    takeoff*: DateTime
    cancelled*: bool

  Ticket* = object
    id* {.primary, autoIncrement.}: ID
    fly_id* {.references: Fly.id.}: ID
    seat*: Positive
    cost*: Natural

  Purchase* = object
    id* {.primary, autoIncrement.}: ID
    international_code*: ID
    ticket_id* {.references: Ticket.id, uniqueIndex.}: ID
    timestamp*: DateTime

# ---

const dbPath {.strdefine.} = "db.sqlite3"

template db*: untyped =
  ponairi.open(dbPath, "", "", "")

proc initDB* =
  db.create(
    Admin, AuthCookie,
    Country, City, Airport, Company, Airplane, Fly, Ticket, Purchase)

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

proc addFly*(aid: ID, pilot: string, org, dest: ID, t: DateTime,
    cost: Natural): ID =
  result = db.insertID Fly(
    airplane_id: aid,
    pilot: pilot,
    origin_id: org,
    destination_id: dest,
    takeoff: t)

  let ap = db.find(Airplane, sql"SELECT * FROM Airplane WHERE id = ?", aid)

  let s = db
  s.exec sql"BEGIN"

  for i in 1..ap.capacity:
    s.exec sql"INSERT INTO Ticket (fly_id, seat, cost) VALUES (?, ?, ?)",
        result, i, cost

  s.exec sql"COMMIT"

  debugEcho "done ", result


proc addAdmin*(uname, pass: string) =
  discard db.insertID Admin(
    username: uname,
    hashedPass: $secureHash pass)

proc isAdmin*(uname, pass: string): bool =
  db.getAllRows(sql"""
    SELECT 1
    FROM Admin
    WHERE
      username = ? AND
      hashedPass = ?
  """, uname, $secureHash pass).len == 1

proc addCookieFor*(cookie, uname: string) =
  discard db.insertID(AuthCookie(username: uname, cookie: cookie))

proc removeCookieFor*(cookie: string) =
  db.exec(sql"""
    DELETE FROM AuthCookie a WHERE a.cookie = ?
  """, cookie)

proc isAuthenticated*(cookie: string): bool =
  db.getAllRows(sql"SELECT 1 FROM AuthCookie WHERE cookie = ?", cookie).len != 0


proc getAllAirCompanies*: auto =
  db.find(seq[Company])

proc allAdmins*: seq[(string, )] =
  db.find(
    seq[tuple[name: string]],
    sql"SELECT username FROM Admin")


proc getActiveFlys*(origin_id, dest_id, company_id: Option[int]): auto =
  
  var conds: seq[string]
  if issome company_id:
    discard
  else:
    conds.add "unixepoch(f.takeoff) - unixepoch('now') > 60 * 60 * 1"
  if issome origin_id:
    conds.add fmt"origin_id = {origin_id.get}"
  if issome dest_id:
    conds.add fmt"destination_id = {dest_id.get}"

  db.find(seq[tuple[id: int, origin, dest, company: string,
      takeoff: string, left: int]],
    sql fmt"""
    SELECT 
      f.id,
      ( cto.name ||  ', ' || cno.name ) origin_address,
      ( ctd.name ||  ', ' || cnd.name ) dest_address, 
      cp.name, f.takeoff, (
        (
          SELECT COUNT(1) 
          FROM Ticket t 
          WHERE t.fly_id = f.id
        ) - (
          SELECT COUNT(1)
          FROM Purchase p 
          JOIN Ticket t
          ON 
            p.ticket_id = t.id AND
            t.fly_id = f.id
        )
      )
    FROM 
      Fly f
    
    JOIN Airport po ON po.id = f.origin_id
    JOIN City cto ON po.city_id = cto.id
    JOIN Country cno ON cno.id = cto.country_id

    JOIN Airport pd ON pd.id = f.destination_id
    JOIN City ctd ON pd.city_id = ctd.id
    JOIN Country cnd ON cnd.id = ctd.country_id

    JOIN Airplane ap ON ap.id = f.airplane_id
    JOIN Company cp ON ap.company_id = cp.id

    WHERE {conds.join " AND "}

    ORDER BY f.takeoff DESC
  """)

proc getAvailableSeats*(fid: ID): auto =
  db.find(seq[tuple[id: ID, seat: int, cost: Natural]],
      sql"""
    SELECT t.id, t.seat, t.cost
    FROM Ticket t
    WHERE 
      t.fly_id = ? AND
      NOT EXISTS (
        SELECT 1 
        FROM Purchase p
        WHERE p.ticket_id = t.id
      )
    ORDER BY t.seat
  """, fid)

  # FIXME unique constraint does not work

proc registerTicket*(ticketId, internationalCode: int): ID =
  db.insertID(Purchase(
    internationalCode: internationalCode,
    ticket_id: ticketId,
    timestamp: now()))


proc deleteCompany*(cid: ID) =
  db.exec sql"DELETE FROM Company WHERE id = ?", cid

proc getCompany*(cid: ID): Company =
  db.find(Company, sql"SELECT * FROM Company WHERE id = ?", cid)

proc updateCompany*(id: ID, name: string) =
  db.exec sql"UPDATE Company SET name = ? WHERE id = ?", name, id

proc getCities*: auto =
  db.find(seq[tuple[id: ID, location: string]],
      sql"""
    SELECT ct.id, ct.name || ' - ' || cn.name
    FROM CITY ct
    JOIN Country cn
    ON ct.country_id = cn.id
  """)

proc getTransactions*: auto =
  db.find(seq[tuple[id, fly_id, internationalCode: ID, timestamp: string]],
      sql"""
    SELECT p.id, f.id, p.international_code, p.timestamp
    FROM Purchase p
    JOIN Ticket t
    ON p.ticket_id = t.id
    JOIN Fly f
    ON f.id = t.fly_id
    ORDER BY p.timestamp DESC
  """)
