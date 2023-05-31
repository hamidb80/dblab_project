import std/[random, db_sqlite, strutils, sequtils]
import dbm

let
  companies = @[
    "Mahan Air",
    "Kish Air",
    "Iran Air"]

  airplanes: seq[tuple[model: string, capacity: int]] = @[
    ("Boeing 707", 137),
    ("Boeing 777", 368),
    ("Boeing 727", 106),
    ("Airbus A321", 185),
    ("Airbus A380", 525),
    ("Embraer Lineage 1000E", 19)]

  pilots = @[
    "Amelia Earhart",
    "Baron Manfred Von Richthoven",
    "General James H",
    "Noel Wien",
    "Chesley Sully Sullenberger",
    "General Charles E. Yeager",
    "Erich Hartmann",
    "Robert A. Hoover"]

  locations = {
    "Iran": @{
      "Tehran": @["Imam Khomeini", "Mehr Abad"],
      "Tabas": @["Tabas"],
      "Mashhad": @["Shahid Hashemi Nejad"],
      "Abadan": @["Ayat-Allah Jami"],
      "Zanjan": @["Shohadaye Zanjan"],
      "Gorgan": @["Gorgran AirPort"],
      "Khoram Abad": @["Shohadye Khoram Abad"],
      "Qom": @["Kooshk Nosrat"],
      "Yazd": @["Shahid Sadooghi"],
      "Hormozgan": @["Kish", "Qeshm", "Aboo Mosa"],
    },

    "Turkey": @{
      "Antalia": @["Antalia Airport"],
      "Estambok": @["Atatork", "Gookchen", "New Estambool"],
    },

    "Iraq": @{
      "Najaf": @["Najaf Airport"],
      "Baghdad": @["Mootana"],
    }
  }


when isMainModule:
  randomize()
  initDB()

  for (country, cities) in locations:
    let coi = addCountry country
    for (city, airports) in cities:
      let cii = addCity(coi, city)
      for ap in airports:
        discard addAirport(cii, ap)

  # https://stackoverflow.com/questions/2279706/select-random-row-from-a-sqlite-table

  for c in companies:
    let ci = addCompany c
    for i in 1..rand(1..20):
      let airplane =  sample airplanes
      discard addAirplane(airplane.model, airplane.capacity, ci)
