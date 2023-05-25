import std/[macros, strformat, options, strtabs, strutils]
import karax/[karaxdsl, vdom], jester
import macroplus

##
## type
##   KFormCollection = object
##     inititializer: proc
##     parser: proc
##

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

proc fromForm[T](data: StringTableRef): T =
  for k, v in result.fieldPairs:
    v = conv(data[k], v.type)
      # when v.type is Option:
      #   if k in data:
      #     conv data[k], v.type
      #   else:
      #     none v.type
      # else:
        # conv data[k], v.type

      # ---

func toInput(formName, formLabel: string): VNode =
  buildHtml tdiv:
    label:
      text formLabel

    input(name = formName, className = "form-control")

func vbtn(content: string): VNode =
  buildHtml button(className = "w-100"):
    text content

# ---

macro kform*(options, stmt): untyped =
  var
    htmlForm = buildHtml tdiv()
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

  newTree(nnkTupleConstr,
    newColonExpr(ident"html", newlit $htmlForm),
    newColonExpr(ident"dataStructure", 
    newCall(ident"default", newTupleDef entries)))


let 
  ff = kform ():
    uname as "user name": input string
    pass as "password": input string
    submit "login"


# --- verbatim <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

when isMainModule:
  echo ff.html
  # let st = newStringTable {
  #   "name": "1",
  #   "value": "2"}

  # echo st

  # type Obj = object
  #   name: string
  #   value: int

  # echo fromForm[Obj](st)
