import std/[macros, strformat, options, strtabs, strutils, sequtils, sugar, times]
import karax/[karaxdsl, vdom], jester
import macroplus
import utils, ui

# --- meta

func callee(n: NimNode): NimNode =
  expectKind n, {nnkCommand, nnkCall}
  n[CallIdent]

func newTupleDef(identDefs: seq[NimNode]): NimNode =
  newTree(nnkTupleTy).add identDefs

# ---

type
  Secret* = object
  ID* = int64


func htmlType*(T: type int): string = "input"
func htmlType*(T: type string): string = "input"
func htmlType*(T: type Secret): string = "password"
func htmlType*(T: type DateTime): string = "datetime-local"

template nimtype*(T: type int): untyped = int
template nimtype*(T: type string): untyped = string
template nimtype*(T: type Secret): untyped = string
template nimtype*(T: type DateTime): untyped = DateTime
template nimtype*(T: type ID): untyped = ID

func conv(a: string, dest: type int): int = parseInt a
func conv(a: string, dest: type int64): int64 = parseBiggestInt a
func conv(a: string, dest: type string): string = a
func conv(a: string, dest: type float): float = parseFloat a

proc conv(a: string, dest: type DateTime): DateTime =
  parse(a, "yyyy-MM-dd'T'hh:mm")

proc fromForm*[T: tuple](data: StringTableRef | Table[string, string]): T =
  for k, v in result.fieldPairs:
    v =
      when v.type is Option:
        if k in data:
          conv(data[k], v.type.T)
        else:
          none v.type.T

      else:
        conv(data[k], v.type)

# ---

func toHiddenInput(formName: string, defaultValue: NimNode): NimNode =
  quote:
    input(name = `formName`, type = "hidden", value = $`defaultValue`)

func findfn[T](s: seq[T], p: T -> bool): Option[T] =
  for i in s:
    if p(i):
      return some i

func isIconPragma(n: NimNode): bool =
  n.kind == nnkExprColonExpr and n[0].eqident "icon"

func iconName(pragmas: seq[NimNode]): string =
  let t = pragmas.findfn(isIconPragma)

  if issome t: t.get[1].strval
  else: ""


func toInput(formName, formLabel: string, inputtype,
    defaultValue: NimNode, pragmas: seq[NimNode]): NimNode =

  let iconName = pragmas.iconName

  quote:
    tdiv:
      customLabel(`formLabel`, `iconName`)

      input(name = `formName`, class = "form-control", type = `inputtype`,
          value = $`defaultValue`)

func toSelect(formName, formLabel: string, defaultValue: NimNode,
    options: NimNode, pragmas: seq[NimNode]): NimNode =

  let iconName = pragmas.iconName

  quote:
    tdiv:
      customLabel(`formLabel`, `iconName`)

      select(name = `formName`, class = "form-control",
          value = $`defaultValue`):
        for (value, name) in `options`:
          option(value = $value):
            text $name

func vbtn(content: string, pragmas: seq[NimNode]): NimNode =
  let iconName = pragmas.iconName
  quote:
    button(class = "w-100 btn btn-primary mt-4"):
      text `content`
      text " "
      icon `iconName`

func vShowInfo(label, content: NimNode, pragmas: seq[NimNode]): NimNode =
  let iconName = pragmas.iconName

  quote:
    buildhtml tdiv(class = "w-100 justify-content-between"):
      namedicon `label`, `iconName`
      span:
        text $`content`


# ---

macro kform*(inputs, stmt): untyped =
  var
    htmlForm = newStmtList()
    entries: seq[NimNode]

  for s in stmt:
    # echo treeRepr s

    case s.kind
    of nnkInfix:
      assert s[InfixIdent] == ident"as"
      let
        key = s[InfixLeftSide]
        label = s[InfixRightSide]
        action = s[InfixBody][0]

      case action.kind
      of nnkAsgn:
        expectKind action[AsgnLeftSide], nnkCommand

        let
          spec = action[AsgnLeftSide]
          dataType = spec[CommandArgs[0]]
          dataTypeResolved = newcall(ident"nimtype", dataType)

          (elem, index) = block:
            let t = spec.callee
            case t.kind
            of nnkIdent: (t.strVal, newlit -1)
            of nnkBracketExpr: (t[0].strVal, t[1])
            else: raisee(ValueError, "invalid element")

          (value, pragmas) = block:
            let t = action[AsgnRightSide]
            case t.kind
            of nnkPragmaExpr:
              (t[0], t[1].toseq)
            else:
              (t, @[])

          vnode =
            case elem:
            of "input":
              entries.add newIdentDefs(key, dataTypeResolved)
              toInput(key.strVal, label.strval,
                newcall(ident"htmltype", dataType),
                value, pragmas)

            of "hidden":
              entries.add newIdentDefs(key, dataTypeResolved)
              toHiddenInput(key.strVal, value)

            of "select":
              entries.add newIdentDefs(key, dataTypeResolved)
              toSelect(key.strVal, label.strval, value, index, pragmas)

            else: raisee ValueError, "invalid form entity"

        htmlForm.add vnode

      else:
        raisee ValueError, "invalid node kind, expected nnkCommand"

    of nnkCommand:
      let
        name = s[CommandIdent].strval
        (label, pragmas) = block:
          let t = s[CommandArgs[0]]
          case t.kind
          of nnkPragmaExpr: (t[0].strval, t[1].toseq)
          else: (t.strVal, @[])

      case name
      of "submit":
        htmlForm.add vbtn(label, pragmas)
      else:
        raisee(ValueError, fmt"invalid command {name}")

    of nnkAsgn:
      let
        left = s[AsgnLeftSide]
        cmd = left.callee.strval
        label = left[CallArgs[0]]
        right = s[AsgnRightSide]
        (value, options) =
          case right.kind
          of nnkPragmaExpr: (right[0], right[1].toseq)
          else: (right, @[])

      case cmd
      of "show":
        htmlForm.add vShowInfo(label, value, options)

      else:
        raisee(ValueError, fmt"invalid callee {cmd}")


    else:
      raisee(ValueError, fmt"invalid node kind {s.kind} in main body")

  result = newTree(nnkTupleConstr,
    newColonExpr(ident"toVNode", newproc(
      params = @[ident"VNode"] & inputs.toseq.map(n => newIdentDefs(n[0], n[1])),
      body = newCall(ident"buildHTML", ident"tdiv", htmlform))),
    newColonExpr(ident"data",
      newCall(ident"default", newTupleDef entries)))


when isMainModule:
  let
    ff = kform (du: string, code: string):
      uname as "user name": input string = du
      pass as "password": input Secret = ""
      show "capcha" = code {.icon: "barcode".}
      submit "login"

  echo ff.toVNode("hey", "wow")
  echo ff.data.type
