extends Object
class_name Lambda

## 仿python lambda格式对象[br]
## Ginq2.0不曾使用，先保留实现[br]
## [codeblock]
## Lambda.new("x,y => x > y").call(1,2)
## [/codeblock]


var source_code:String
const LAMBDA_FORMAT = """func lambda({args}):\n\treturn {express}"""

func _init(lambda:String):
	source_code = lambda

func invoke(args:Array):
	var lambda_name = 'lambda'
	var regex = RegEx.new()
	regex.compile("(?<args>[\\w, ]+)=>(?<express>.+)")
	var result = regex.search(source_code)
	if result:
		var argsStr = result.get_string('args')
		var express = result.get_string('express')
		var lambda_code = LAMBDA_FORMAT.format({args=argsStr, express=express})

		var script = GDScript.new()
		script.set_source_code(lambda_code)
		script.reload()
		var obj = RefCounted.new()
		obj.set_script(script)
		var ret = obj.callv(lambda_name, args)
		return ret

