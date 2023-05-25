import std/[macros, strformat, options, strtabs, strutils, sequtils, sugar]
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

func conv(a: string, dest: type int): int = parseInt a
func conv(a: string, dest: type string): string = a
func conv(a: string, dest: type float): float = parseFloat a

proc fromForm*[T](data: StringTableRef): T =
  for k, v in result.fieldPairs:
    v = conv(data[k], v.type)

# ---

func toHiddenInput(formName: string, defaultValue: NimNode): NimNode =
  quote:
    input(name = `formName`, type = "hidden", value = $`defaultValue`)

func toInput(formName, formLabel: string, defaultValue: NimNode): NimNode =
  quote:
    tdiv:
      label:
        text `formLabel`

      input(name = `formName`, class = "form-control",
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
    button(class = "w-100"):
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
          (elem, index) = block:
            let t = spec.callee
            case t.kind
            of nnkIdent: (t.strVal, newlit -1)
            of nnkBracketExpr: (t[0].strVal, t[1])
            else: raisee(ValueError, "invalid element")

          vnode =
            case elem:
            of "input":
              entries.add newIdentDefs(key, dataType)
              toInput(key.strVal, label.strval, value)

            of "hidden":
              entries.add newIdentDefs(key, dataType)
              toHiddenInput(key.strVal, value)

            of "select":
              entries.add newIdentDefs(key, dataType)
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
    newColonExpr(ident"dataStructure",
      newCall(ident"default", newTupleDef entries)))

  echo repr result

when isMainModule:
  let
    ff = kform (du: string):
      uname as "user name": input string = du
      pass as "password": input string = ""
      submit "login"

  echo ff.toVNode("hey")
  echo ff.dataStructure.type
