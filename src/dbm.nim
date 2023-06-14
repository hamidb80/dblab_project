import std/[times, options, sha1, strformat, strutils]
import ponairi
import utils

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

  # Plane* = object
  #   id* {.primary, autoIncrement.}: ID
  #   company_id* {.references: Company.id.}: ID
  #   model*: string
  #   capacity*: Positive
  #   deprecated*: bool

  Fly* = object
    id* {.primary, autoIncrement.}: ID
    pilot*: string
    plane_id* {.references: Plane.id.}: ID
    origin_id* {.references: Airport.id.}: ID
    destination_id* {.references: Airport.id.}: ID
    company_id* {.references: Company.id.}: ID
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
    Country, City, Airport, Company, # Plane,
    Fly, Ticket, Purchase)

# ---

proc addCountry*(name: string): ID =
  db.insertID Country(name: name)

proc addCity*(country: ID, name: string): ID =
  db.insertID City(country_id: country, name: name)

proc addAirport*(city: ID, name: string): ID =
  db.insertID Airport(city_id: city, name: name)

proc addCompany*(name: string): ID =
  db.insertID Company(name: name)

proc addPort*(cityId: ID, name: string): ID =
  db.insertID Airport(cityID: cityId, name: name)

# proc addPlane*(model: string, cap: int, company: ID): ID =
#   db.insertID Plane(model: model, company_id: company, capacity: cap)

proc addFly*(company_id: ID, pilot: string, org, dest: ID, t: DateTime,
    cost, capacity: Natural): ID =

  let s = db

  result = db.insertID Fly(
    pilot: pilot,
    company_id: company_id,
    origin_id: org,
    destination_id: dest,
    takeoff: t)

  s.transaction:
    for i in 1..capacity:
      s.exec sql"INSERT INTO Ticket (fly_id, seat, cost) VALUES (?, ?, ?)",
          result, i, cost

proc addAdmin*(uname, pass: string) =
  db.insert Admin(
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
  db.insert(AuthCookie(username: uname, cookie: cookie))

proc removeCookieFor*(cookie: string) =
  db.exec(sql"""
    DELETE FROM AuthCookie WHERE cookie = ?
  """, cookie)

proc isAuthenticated*(cookie: string): bool =
  db.getAllRows(sql"SELECT 1 FROM AuthCookie WHERE cookie = ?", cookie).len != 0


proc getAllAirCompanies*: auto =
  db.find(seq[Company])

proc allAdmins*: seq[(string, )] =
  db.find(
    seq[tuple[name: string]],
    sql"SELECT username FROM Admin")

func showIfTrue[T](cond: bool, value: T): T =
  if cond: value
  else: default T

proc getFlys*(origin_id, dest_id, fly_id, company_id:
    Option[ID] = none ID, onlyFuture = false): auto =

  var
    conds: seq[string]
    companyFilter: string

  if issome company_id:
    companyFilter = "AND cp.id = " & $company_id.get
  else:
    conds.add "NOT f.cancelled"

  if onlyFuture:
    conds.add "unixepoch(f.takeoff) - unixepoch('now') > 60 * 60 * 1"

  if isSome fly_id:
    conds.add "f.id = " & $fly_id.get

  db.find(seq[tuple[id: ID, pilot, origin, dest, originPort, destPort,
    companyName: string, companyId: ID, takeoff: string,
    capacity, used: int, cancelled: bool]],
    sql fmt"""
    SELECT 
      f.id,
      f.pilot,
      ( cto.name ||  ' - ' || cno.name ) origin_address,
      ( ctd.name ||  ' - ' || cnd.name ) dest_address, 
      po.name, pd.name,
      cp.name, cp.id, f.takeoff, (
        SELECT COUNT(1) 
        FROM Ticket t 
        WHERE t.fly_id = f.id
      ) capacity, 
      (
        SELECT COUNT(1)
        FROM Purchase p 
        JOIN Ticket t
        ON 
          p.ticket_id = t.id AND
          t.fly_id = f.id
      ) used,
      f.cancelled
    FROM 
      Fly f
    
    JOIN Airport po ON po.id = f.origin_id
    JOIN City cto ON po.city_id = cto.id {iff(issome origin_id, "AND cto.id = " & $origin_id.get, "")}
    JOIN Country cno ON cno.id = cto.country_id

    JOIN Airport pd ON pd.id = f.destination_id
    JOIN City ctd ON pd.city_id = ctd.id {iff(issome dest_id, "AND ctd.id = " & $dest_id.get, "")}
    JOIN Country cnd ON cnd.id = ctd.country_id

    JOIN Company cp ON f.company_id = cp.id {companyFilter}

    {showIfTrue conds.len != 0, "WHERE"}
    {conds.join " AND "}

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

proc allPorts*: auto =
  db.find(seq[tuple[id: ID, name, location: string]],
      sql"""
    SELECT a.id, a.name, (ct.name || ' - ' || cn.name) FROM Airport a
    JOIN City ct ON ct.id = a.city_id
    JOIN Country cn ON cn.id = ct.country_id
  """)

proc allLocations*: auto =
  db.find(seq[tuple[city, country: string]],
      sql"""
    SELECT ct.name, cn.name 
    FROM City ct
    JOIN Country cn 
    ON ct.country_id = cn.id
    ORDER BY ct.id DESC
  """)

proc addLocation*(country, city: string): ID =
  let s = db

  discard s.tryInsertID(sql"""
    INSERT INTO Country (name) VALUES (?)
    """, country)

  let
    newCountry = s.find(Country, sql"SELECT * FROM Country WHERE name = ?", country)
    r = db.getValue(ID, sql"""
      SELECT ct.id FROM City ct
      JOIN Country cn
      ON cn.id = ?
      WHERE ct.name = ?
    """, newCountry.id, city)

  if isSome r:
    get r
  else:
    s.insertID City(country_id: newCountry.id, name: city)

proc registerTicket*(ticketId: ID, internationalCode: int): ID =
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


proc cancellFly*(fid: ID) =
  db.exec sql"UPDATE Fly SET cancelled = ? WHERE id = ?", true, fid

proc getPurchaseFullInfo*(pid: ID): auto =
  let
    p = db.find(Purchase, sql"SELECT * FROM Purchase WHERE id = ?", pid)
    t = db.find(Ticket, sql"SELECT * FROM Ticket WHERE id = ?", p.ticket_id)
    f = getFlys(flyid = some t.flyid)[0]

  (purchase: p, ticket: t, fly: f)
