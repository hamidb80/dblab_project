# Package

version       = "0.0.1"
author        = "hamidb80"
description   = "airport project - DB lab of CE Shahed University"
license       = "MIT"
srcDir        = "src"
bin           = @["dblab"]


# Dependencies

requires "nim >= 1.6.12"
requires "macroplus@0.2.4"

requires "jester@#head"
requires "ponairi"
requires "karax"

task go, "go":
  exec "nim r src/main" 

task data, "date gen":
  exec "nim r src/datagen" 

task clear, "clear":
  rmfile "./db.sqlite3"
