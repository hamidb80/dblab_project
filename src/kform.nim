import std/[macros, strformat, options, strtabs, strutils, sequtils, sugar, times]
import karax/[karaxdsl, vdom], jester
import macroplus

##
## type
##   KFormCollection = object
##     inititializer: proc
##     parser: proc
##

# type
#   Form = object
#     fields: seq[FormField]

#   FormField = object
#     kind: FormFieldKind
#     name: string
#     features

#   FormFieldKind = enum
#     ffkInput
#     ffkHidden
#     ffkSelect


# --- meta

template getAssert(node: NimNode, k: NimNodeKind, pattern: NimNode): untyped =
  if node.kind == k:
    replaceIdent node, ident"_", pattern
  else:
    raisee ValueError, "invalid node kind: '" & $node.kind & "' expected '" &
        $k & "' for " & node.repr

template q(code): untyped = inlineQuote code

template raisee(err, msg): untyped =
  raise newException(err, msg)

template `:=`(container, value): untyped =
  let container = value
  value

func replaceIdent(what, sub, repl: NimNode): NimNode =
  case what.kind
  of AtomicNodes:
    result =
      if what == sub: repl
      else: what
  else:
    for n in what:
      result = copyNimNode what
      result.add replaceIdent(n, sub, repl)


func callee(n: NimNode): NimNode =
  expectKind n, {nnkCommand, nnkCall}
  n[CallIdent]

template emp: untyped =
  newEmptyNode()

func newTypeSection(typedef: NimNode): NimNode =
  newTree(nnkTypeSection, typedef)

func newTypeDef(obj: NimNode, name: string): NimNode =
  newTree(nnkTypeDef,
    exported ident name,
    emp,
    obj)

func newObjectDef(identDefs: seq[NimNode]): NimNode =
  newTree(nnkObjectTy,
    emp,
    emp,
    newNimNode(nnkRecList).add identDefs)

func newTupleDef(identDefs: seq[NimNode]): NimNode =
  newTree(nnkTupleTy).add identDefs

# ---

template `?`(T: typedesc): untyped = Option[T]

type Secret* = object

func htmlType*(T: type int): string = "input"
func htmlType*(T: type string): string = "input"
func htmlType*(T: type Secret): string = "password"
func htmlType*(T: type DateTime): string = "datetime-local"

template nimtype*(T: type int): untyped = int
template nimtype*(T: type string): untyped = string
template nimtype*(T: type Secret): untyped = string
template nimtype*(T: type DateTime): untyped = DateTime

func conv(a: string, dest: type int): int = parseInt a
func conv(a: string, dest: type string): string = a
func conv(a: string, dest: type float): float = parseFloat a

# TODO https://nim-lang.org/docs/times.html
proc conv(a: string, dest: type DateTime): DateTime = now() 

proc fromForm*[T: tuple](data: StringTableRef | Table[string, string]): T =
  for k, v in result.fieldPairs:
    v = conv(data[k], v.type)

# ---

func toHiddenInput(formName: string, defaultValue: NimNode): NimNode =
  quote:
    input(name = `formName`, type = "hidden", value = $`defaultValue`)

func toInput(formName, formLabel: string, inputtype,
    defaultValue: NimNode): NimNode =
  quote:
    tdiv:
      label:
        text `formLabel`

      input(name = `formName`, class = "form-control", type = `inputtype`,
          value = $`defaultValue`)

func toSelect(formName, formLabel: string, defaultValue: NimNode,
    options: NimNode): NimNode =
  quote:
    tdiv:
      label:
        text `formLabel`

      select(name = `formName`, class = "form-control",
          value = $`defaultValue`):
        for o in `options`:
          option(value = $o)

func vbtn(content: string): NimNode =
  quote:
    button(class = "w-100 btn btn-primary mt-4"):
      text `content`

# ---

macro kform*(inputs, stmt): untyped =
  var
    htmlForm = newStmtList()
    entries: seq[NimNode]

  # echo treeRepr stmt

  for s in stmt:
    echo treeRepr s

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
          value = action[AsgnRightSide]
          spec = action[AsgnLeftSide]
          dataType = spec[CommandArgs[0]]
          dataTypeResolved = newcall(ident"nimtype", dataType)
          (elem, index) = block:
            let t = spec.callee
            case t.kind
            of nnkIdent: (t.strVal, newlit -1)
            of nnkBracketExpr: (t[0].strVal, t[1])
            else: raisee(ValueError, "invalid element")

          vnode =
            case elem:
            of "input":
              entries.add newIdentDefs(key, dataTypeResolved)
              toInput(key.strVal, label.strval, newcall(ident"htmltype",
                  dataType), value)

            of "hidden":
              entries.add newIdentDefs(key, dataTypeResolved)
              toHiddenInput(key.strVal, value)

            of "select":
              entries.add newIdentDefs(key, dataTypeResolved)
              toSelect(key.strVal, label.strval, value, index)

            else: raisee ValueError, "invalid form entity"

        htmlForm.add vnode

      else:
        raisee ValueError, "invalid node kind, expected nnkCommand"

    of nnkCommand:
      let
        name = s[CommandIdent].strval
        label = s[CommandArgs[0]].strval

      case name
      of "submit":
        htmlForm.add vbtn(label)
      else:
        raisee(ValueError, fmt"invalid command {name}")

    else:
      raisee(ValueError, fmt"invalid node kind {s.kind} in main body")

  result = newTree(nnkTupleConstr,
    newColonExpr(ident"toVNode", newproc(
      params = @[ident"VNode"] & inputs.toseq.map(n => newIdentDefs(n[0], n[1])),
      body = newCall(ident"buildHTML", ident"tdiv", htmlform))),
    newColonExpr(ident"data",
      newCall(ident"default", newTupleDef entries)))

  echo repr result

when isMainModule:
  let
    ff = kform (du: string):
      uname as "user name": input string = du
      pass as "password": input Secret = ""
      submit "login"

  echo ff.toVNode("hey")
  echo ff.data.type
