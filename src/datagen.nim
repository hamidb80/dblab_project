import std/[random, sugar, times]
import dbm

let
  companies = @[
    "آتا",
    "ماهان",
    "ایران ایر"]

  airplanes: seq[tuple[model: string, capacity: int]] = @[
    ("Boeing 707", 137),
    ("Boeing 727", 106),
    ("Embraer Lineage 1000E", 19)]

  pilots = @[
    "فریدون ذوالفقاری",
    "محمود اسکندری",
    "علیرضا یاسینی",
    "جلیل زندی",
    "منوچهر محققی",
    "حسین خلعتبری",
    "عباس بابایی",
    "علی اکبر شیرودی"]

  locations = {
    "ایران": @{
      "تهران": @[" فروگاه امام خمینی",
          "فرودگاه مهرآباد"],
      "طبس": @["طبس"],
      "مشهد": @["فرودگاه شهید هاشمی نژاد"],
      "آبادان": @["فرودگاه آیت الله جمی"],
      "زنجان": @["فرودگاه شهدای زنجان"],
      "گرگان": @["فرودگان گرگان"],
      "خرم آباد": @["فرودگاه شهدای خرم آباد"],
      "قم": @["فرودگاه کوشک نصرت"],
      "یزد": @["فرودگاه شهید صدوقی"],
      "هرمزگان": @["فرودگاه کیش", "فرودگاه قسم",
          "فرودگاه ابوموسی"],
    },

    "ترکیه": @{
      "آنتالیا": @["فرودگاه آنتالیا"],
      "استامبول": @["فرودگاه آتاتورک",
          "فرودگاه جدید استامبول"],
    },

    "عراق": @{
      "نجف": @["فروگاه نجق"],
      "بغداد": @["فرودگاه موتانا"],
    }
  }


when isMainModule:
  randomize()
  initDB()

  addAdmin("root", "1")

  var airports_ids: seq[ID]

  for (country, cities) in locations:
    let coi = addCountry country
    for (city, airports) in cities:
      let cii = addCity(coi, city)
      for ap in airports:
        airports_ids.add addAirport(cii, ap)

  for c in companies:
    let
      ci = addCompany c
      vs = collect:
        for i in 1..rand(1..20):
          let airplane = sample airplanes
          addAirplane(airplane.model, airplane.capacity, ci)

    for i in 1..rand(1..30):
      let
        o = sample airports_ids
        d = sample airports_ids
        t = now() + initDuration(minutes = rand(1..1000))

      discard addFly(sample vs, sample pilots, o, d, t)
