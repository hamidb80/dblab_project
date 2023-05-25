import std/[macros, strformat, options, strtabs]
import karax/[karaxdsl, vdom], jester
import macroplus

##
## type
##   KFormCollection = object
##     inititializer: proc
##     parser: proc
##


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


func toInput(formName, formLabel: string): VNode =
  buildHtml tdiv:
    label:
      text formLabel

    input(name = formName, className = "form-control")

func vbtn(content: string): VNode =
  buildHtml button(className = "w-100"):
    text content

func callee(n: NimNode): NimNode =
  expectKind n, {nnkCommand, nnkCall}
  n[CallIdent]

template emp: untyped =
  newEmptyNode()

func newTypeSection(typedef: NimNode): NimNode =
  newTree(nnkTypeSection, typedef)

func newTypeDef(obj: NimNode, name: string): NimNode =
  newTree(nnkTypeDef,
    ident name,
    emp,
    obj)

func newObjectDef(identDefs: seq[NimNode]): NimNode =
  newTree(nnkObjectTy,
    emp,
    emp,
    newNimNode(nnkRecList).add identDefs)


template `?`(T: typedesc): untyped =
  Option[T]


proc fromForm[T](data: StringTableRef): T = 
  for k, v in result.fieldPairs:
    echo k, " <--", v.hasCus


macro kform*(options, stmt): untyped =
  var
    htmlForm = ""
    entries: seq[NimNode]

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
      of nnkCommand:
        let
          elemenet = action.callee.strVal
          `type` = action[CommandArgs[0]]
          vnode =
            case elemenet:
            of "input":
              entries.add newIdentDefs(key, `type`)
              toInput(key.strVal, label.strval)

            # of "hidden": discard
            # of "select": discard
            else: raisee ValueError, "invalid form entity"

        htmlForm &= $vnode

      else:
        raisee ValueError, "invalid node kind, expected nnkCommand"

    of nnkCommand:
      let
        name = s[CommandIdent].strval
        label = s[CommandArgs[0]].strval

      case name
      of "submit":
        htmlForm &= vbtn(label)
      else:
        raisee(ValueError, fmt"invalid command {name}")

    else: raisee(ValueError, fmt"invalid node kind {s.kind} in main body")

  echo "-------------------------"
  echo htmlForm
  echo repr newTypeSection newTypeDef(newObjectDef entries, "randomType")

kform ():
  uname as "user name": input string
  pass as "password": input Password
  submit "login"


when isMainModule:

  let st = newStringTable {
    "name": "1",
    "value":" 2"
  }

  echo st

  type Obj = object 
    name: string

  echo fromForm[Obj](st)