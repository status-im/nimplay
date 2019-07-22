import compiler / [ast, vmdef, vm, nimeval, options, parser, idents, condsyms,
           nimconf, extccomp, astalgo, llstream, pathutils]
import json
import os


import
  ../nimplay/types


type
    VariableType* = object
        name: string
        var_type: string

type
  EventType* = object
    name: string
    var_type: string
    indexed: bool

type
    FunctionSignature* = object
        name: string
        inputs: seq[VariableType]
        outputs: seq[VariableType]
        constant: bool
        payable: bool

type
    EventSignature* = object
      name: string
      inputs: seq[EventType]
      indexed: bool


proc string_to_ast*(s: string): PNode {.raises: [Exception] .} =
  var conf = newConfigRef()
  var cache = newIdentCache()
  condsyms.initDefines(conf.symbols)
  conf.projectName = "stdinfile"
  conf.projectFull = "stdinfile".AbsoluteFile
  conf.projectPath = canonicalizePath(conf, getCurrentDir().AbsoluteFile).AbsoluteDir
  conf.projectIsStdin = true
  loadConfigs(DefaultConfig, cache, conf)
  extccomp.initVars(conf)
  var node = parseString(s, cache, conf)
  if len(node.sons) > 1:
    result = node
  else:
    result = node.sons[0]


proc generate_function_signature(proc_def: PNode): FunctionSignature =
  doAssert(proc_def.kind == nkFuncDef or proc_def.kind == nkProcDef)
  var
    func_sig = FunctionSignature()

  for child in proc_def.sons:
    case child.kind:
    of nkPostfix:
      func_sig.name = child[1].ident.s
    of nkFormalParams:
      for param in  child:
        case param.kind
        of nkIdent:
          func_sig.outputs.add(
            VariableType(
              name: "out1",
              var_type: param.ident.s
            )
          )
        of nkIdentDefs:
          func_sig.inputs.add(
            VariableType(
              name: param.sons[0].ident.s,
              var_type: param.sons[1].ident.s
            )
          )
        of nkEmpty:
          discard
        else:
          raise newException(Exception, "unknown param type")
    of nkPragma:
      if child[0].kind == nkIdent and child[0].ident.s == "payable":
        func_sig.payable = true
    else:
      discard
  return func_sig


proc generate_event_signature(proc_def: PNode): EventSignature =
  doAssert(proc_def.kind == nkProcDef)
  var
    event_sig = EventSignature()
  for child in proc_def.sons:
    case child.kind:
    of nkIdent:
      event_sig.name = child.ident.s
    of nkFormalParams:
      for param in child:
        if param.kind == nkIdentDefs:
          var
            ev: EventType
          if param[0].kind == nkPragmaExpr and param[0][1].kind == nkPragma:
              ev = EventType(
                name: param.sons[0].sons[0].ident.s,
                var_type: param.sons[1].ident.s,
                indexed: true
              )
          else:
            ev = EventType(
              name: param.sons[0].ident.s,
              var_type: param.sons[1].ident.s,
              indexed: false
            )
          event_sig.inputs.add(ev)
    else:
      discard

  event_sig  # return


proc generateSignatures(stmts: PNode): (seq[FunctionSignature], seq[EventSignature]) =
  var
    public_functions: seq[FunctionSignature]
    events: seq[EventSignature]
  for child in stmts:
    if child.kind == nkCall and len(child.sons) > 2:
      var first_son = child.sons[0]
      if first_son.kind == nkIdent and first_son.ident.s == "contract":
        var main_block = child
        for b in main_block.sons:
          if b.kind == nkStmtList:
            for s in b.sons:
              if s.kind == nkFuncDef or s.kind == nkProcDef:
                # only get public functions.
                if s[0].kind == nkPostfix and s[0][0].ident.s == "*":
                  public_functions.add(
                    generate_function_signature(s)
                  )
                                # handle event signature
                elif s[6].kind == nkEmpty:
                  events.add(
                    generate_event_signature(s)
                  )
  return (public_functions, events)


proc generateJSONABI(funcs: seq[FunctionSignature], events: seq[EventSignature]): string =
  var jsonObject = %* []

  proc getVarTypes(var_types: seq[VariableType]): JsonNode =
    var types = %* []
    for t in var_types:
      types.add(%* {
        "name": t.name,
        "type": t.var_type,
      })
    types  # return


  func getFunc(f: FunctionSignature): JsonNode =
    %* {
      "name": f.name,
      "inputs": getVarTypes(f.inputs),
      "outputs": getVarTypes(f.outputs),
      "constant": f.constant,
      "payable": f.payable,
      "type": "function"
    }

  proc getEventTypes(var_types: seq[EventType]): JsonNode =
    var types = %* []
    for t in var_types:
      types.add(%* {
        "name": t.name,
        "type": t.var_type,
        "indexed": t.indexed
      })
    types

  func getEvent(e: EventSignature): JsonNode =
    %* {
      "inputs": getEventTypes(e.inputs),
      "name": e.name,
      "type": "event",
      "anonymous": false
    }

  for fn in funcs:
    jsonObject.add(getFunc(fn))

  for event in events:
    jsonObject.add(getEvent(event))

  $jsonObject  # return


proc main() =
  if paramCount() != 1:
    echo("Requires .nim file with contract() block macro")
    quit()
  if not existsFile(commandLineParams()[0]):
    echo("Requires .nim file with contract() block macro")
    quit()

  var nimFile = commandLineParams()[0]
  let node = string_to_ast(readFile(nimFile))

  if node.kind == nkStmtList:
    let (functions, events) = generateSignatures(node)
    echo(generateJSONABI(functions, events))
  else:
    raise newException(Exception, "Expected nkStmtList")


when is_main_module:
  main()
