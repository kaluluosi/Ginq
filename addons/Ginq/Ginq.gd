extends Object
class_name Ginq

var array: Array : get = getArray
var _operators = []
var _lambdas = []
var host:Object

func _init(iterable: Array,operators:=[],lambdas:=[]):
	array = iterable.duplicate(true)
	_operators = operators
	_lambdas = lambdas
	
func getArray():
	return array
	
func done():
	_init_lambda_host() 
	
	var tempValue = array
	
	# 处理链式操作
	for operator in _operators:
		tempValue = call(operator.method, operator.args, tempValue)
	
	return tempValue
	
# region


func _new_ginq(iterable:Array, operators:=[], lambdas:=[]) -> Ginq:
	return load(self.get_script().get_path()).new(iterable, operators, lambdas)

func _clone() -> Ginq:
	return _new_ginq(array, _operators.duplicate(true), _lambdas.duplicate(true))	

static func eval(code:String):
	var script = GDScript.new()
	script.set_source_code("func eval():\n\treturn "+code)
	script.reload()
	var obj = RefCounted.new()
	obj.set_script(script)
	var ret = obj.eval()
	return ret

static func is_lambda(code:String) -> bool:
	return code.find('lambda') > 0
	
func add_lambda(code:String) -> String:
	var lambda_format = """func {func_name}({args}):\n\treturn {express}"""
		
	var regex = RegEx.new()
	regex.compile("lambda(?<args>[\\w, ]+):(?<express>.+)")
	var result = regex.search(code)
	if result:
		var argsStr = result.get_string('args')
		var express = result.get_string('express')
		var name = 'lambda_{func_name}'.format({func_name=v4('_')})
		var lambda_code = lambda_format.format({args=argsStr, express=express, func_name=name})
		_lambdas.append(lambda_code)
		return name
	else:
		return 'error'

func _init_lambda_host():
	var lambda_codes = '\n'.join(PackedStringArray(_lambdas))

	var script = GDScript.new()
	script.set_source_code(lambda_codes)
	script.reload()
	var hostObj = RefCounted.new()
	hostObj.set_script(script)
	host = hostObj
	
func register_operator(method:String, args):
	_operators.append({method=method, args=args})

# endregion

# region operator define

# 链式操作中不会直接调用处理而是将操作信息注册到操作链里
func filter(lambda: String) -> Ginq:
	var clone = _clone()
	var lambda_name = clone.add_lambda(lambda)
	clone.register_operator('_filter', {lambda_name=lambda_name})
	return clone

# 这才是filter操作的具体的处理函数
func _filter(args, iterable: Array) -> Array:
	var ret:Array = []
	var lambda_name = args.lambda_name
	if host.has_method(lambda_name):
		for v in iterable:
			if host.call(lambda_name, v):
				ret.push_back(v)
		return ret
	else:
		push_error('lambda not found')
		return []
		
func where(lambda:String) -> Ginq:
	"""
	alias of filter
	"""
	return filter(lambda)
	
func map(lambda: String) -> Ginq:
	var clone = _clone()
	var lambda_name = clone.add_lambda(lambda)
	clone.register_operator('_map', {lambda_name=lambda_name})
	return clone
	
func _map(args, iterable:Array) -> Array:
	var ret:Array = []
	var lambda_name = args.lambda_name
	if host.has_method(lambda_name):
		for v in iterable:
			var nv = host.call(lambda_name, v)
			ret.push_back(nv)
		return ret
	else:
		push_error('lambda not found')
		return []
		
func select(lambda:String) -> Ginq:
	"""
	alias of map
	"""
	return map(lambda)
	
func skip(num:int) -> Ginq:
	var clone = _clone()
	clone.register_operator('_skip', {num=num})
	return clone
	
func _skip(args, iterable: Array):
	var num = args.num
	var skipnum = num if num - 1 > 0 else 0
	return iterable.slice(skipnum)

func skip_while(lambda:String) -> Ginq:
	var clone = _clone()
	var lambda_name = clone.add_lambda(lambda)
	clone.register_operator('_skip_while',{lambda_name=lambda_name})
	return clone

func _skip_while(args, iterable:Array) -> Array:
	var start_index = 0
	var lambda_name = args.lambda_name
	if host.has_method(lambda_name):
		for index in range(len(iterable)):
			if host.call(lambda_name, iterable[index]):
				start_index+=1
			else:
				break
		return iterable.slice(start_index)
	else:
		push_error("lambda not found")
		return []

func take(num:int) -> Ginq:
	var clone = _clone()
	clone.register_operator('_take', {num=num})
	return clone
	
func _take(args, iterable:Array) -> Array:
	var num = args.num
	if num <= 0:
		return []
	elif num > len(iterable):
		return iterable
	else:
		return iterable.slice(0, num)
		
func take_while(lambda:String):
	var clone = _clone()
	var lambda_name = clone.add_lambda(lambda)
	clone.register_operator('_take_while', {lambda_name=lambda_name})
	return clone

func _take_while(args, iterable:Array) -> Array:
	var end_index = 0
	var lambda_name = args.lambda_name
	if host.has_method(lambda_name):
		for index in len(iterable):
			if host.call(lambda_name, iterable[index]):
				end_index += 1
			else:
				break
		if end_index == -1:
			return []
		else:
			return iterable.slice(0, end_index)
	else:
		push_error('lambda not found')
		return []

func join(secendIterable:Array, lambda_source_key:String, lambda_inner_key:String) -> Ginq:
	var clone = _clone()
	var lambda_source_key_name = clone.add_lambda(lambda_source_key)
	var lambda_inner_key_name = clone.add_lambda(lambda_inner_key)
	clone.register_operator('_join', {lambda_source_key_name=lambda_source_key_name, lambda_inner_key_name=lambda_inner_key_name, secendIterable=secendIterable})
	return clone

func _join(args, iterable:Array) -> Array:
	var ret = []
	if host.has_method(args.lambda_source_key_name) and host.has_method(args.lambda_inner_key_name):
		for v in iterable:
			var source_key_value = host.call(args.lambda_source_key_name, v)
			for inner in args.secendIterable:
				var inner_key_value = host.call(args.lambda_inner_key_name, inner)
				if source_key_value == inner_key_value:
					ret.push_back([v, inner])
		return ret
	else:
		push_error('lambda not found')
		return []

func concate(iterable:Array) -> Ginq:
	var clone = _clone()
	clone.register_operator('_concate', {iterable=iterable})
	return clone

func _concate(args, iterable:Array) -> Array:
	var target_iterable:Array = args.iterable
	var ret = iterable.duplicate(true)
	for v in target_iterable:
		ret.push_back(v)
	return ret

func order_by(lambda:String = "lambda x:x") -> Ginq:
	var clone = _clone()
	var lambda_name = clone.add_lambda(lambda)
	clone.register_operator('_order_by', {lambda_name=lambda_name})
	return clone

func _order_by(args, iterable:Array) -> Array:
	var lambda_name = args.lambda_name
	if host.has_method(lambda_name):
		var ret = []
		var temp = {}
		for v in iterable:
			var key = host.call(lambda_name, v)
			temp[key] = v

		var sorted_keys = temp.keys()
		sorted_keys.sort()
		for key in sorted_keys:
			ret.push_back(temp[key])
		
		return ret
	else:
		push_error('lambda not found')
		return iterable

func order_by_descending(lambda:String="lambda x:x") -> Ginq:
	var clone = _clone()
	var lambda_name = clone.add_lambda(lambda)
	clone.register_operator('_order_by_descending', {lambda_name=lambda_name})
	return clone

func _order_by_descending(args, iterable:Array) -> Array:
	var lambda_name = args.lambda_name
	if host.has_method(lambda_name):
		var ret = []
		var temp = {}
		for v in iterable:
			var key = host.call(lambda_name, v)
			temp[key] = v

		var sorted_keys = temp.keys()
		sorted_keys.sort()
		var end_index = len(sorted_keys) -1
		while end_index >=0:
			var key = sorted_keys[end_index]
			ret.push_back(temp[key])
			end_index-=1
		
		return ret
	else:
		push_error('lambda not found')
		return iterable

func reverse() -> Ginq:
	var clone = _clone()
	clone.register_operator('_reverse', null)
	return clone

func _reverse(args, iterable:Array) -> Array:
	var ret = []
	for v in iterable:
		ret.push_front(v)
	return ret

func distinct() -> Ginq:
	var clone = _clone()
	clone.register_operator('_distinct', {})
	return clone

func _distinct(args, iterable:Array) -> Array:
	var ret = []
	for v in iterable:
		if v in ret:
			continue
		else:
			ret.push_back(v)
	return ret

func union(secendIterable:Array) -> Ginq:
	var clone = _clone()
	clone.register_operator('_union', {secendIterable=secendIterable})
	return clone

func _union(args, iterable:Array) -> Array:
	var ret = _new_ginq(iterable).concate(args.secendIterable).distinct().done()
	return ret

func intersect(secendIterable:Array) -> Ginq:
	var clone = _clone()
	clone.register_operator('_intersect', {secendIterable=secendIterable})
	return clone

func _intersect(args, iterable:Array) -> Array:
	var ret = []
	for v in iterable:
		if v in args.secendIterable:
			ret.push_back(v)
	return ret

func expect(secendIterable:Array) -> Ginq:
	var clone = _clone()
	clone.register_operator('_expect', {secendIterable=secendIterable})
	return clone	

func _expect(args, iterable:Array) -> Array:
	var ret = []
	iterable = _new_ginq(iterable).concate(args.secendIterable).done()
	for v in iterable:
		if v in ret:
			var index = ret.find(v)
			ret.remove_at(index)
			continue
		else:
			ret.push_back(v)
		
	return ret

func all(lambda:String="lambda x:x") -> bool:
	var temp_array = map(lambda).done()
	var ret = true
	for value in temp_array:
		ret = ret and value
		if not ret:
			return false
	return true

func any(lambda: String="lambda x:x") -> bool:
	var temp_array = map(lambda).done()
	var ret = false
	for value in temp_array:
		ret = ret or value
		if ret:
			return true
	return false

func sum(lambda:String="lambda x:x"):
	var temp_array = map(lambda).done()
	var ret = 0
	for value in temp_array:
		if typeof(value) in [TYPE_INT,TYPE_FLOAT]:
			ret += value
		else:
			push_error('{} is not number'.format({0:value}))
			return -1

	return ret

func min(lambda:String="lambda x:x"):
	var temp_array = map(lambda).done()
	
	var min_value = temp_array.pop_front()
	for value in temp_array:
		if value < min_value:
			min_value = value

	return min_value

func max(lambda:String="lambda x:x"):
	var temp_array = map(lambda).done()

	var max_value = temp_array.pop_front()
	for value in temp_array:
		if value > max_value:
			max_value = value

	return max_value

func average(lambda:String="lambda x:x"):
	var temp_array = map(lambda).done()
	var tempGinq = _new_ginq(temp_array)
	var sum = tempGinq.sum()
	return sum/len(temp_array)

# end region

"""
thanks for Xavier Sellier
https://github.com/binogure-studio/godot-uuid
"""

const MODULO_8_BIT = 256

static func getRandomInt():
  # Randomize every time to minimize the risk of collisions
	randomize()

	return randi() % MODULO_8_BIT

static func uuidbin():
  # 16 random bytes with the bytes on index 6 and 8 modified
	return [
	getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
	getRandomInt(), getRandomInt(), ((getRandomInt()) & 0x0f) | 0x40, getRandomInt(),
	((getRandomInt()) & 0x3f) | 0x80, getRandomInt(), getRandomInt(), getRandomInt(),
	getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
  ]

static func v4(delimiter='-'):
  # 16 random bytes with the bytes on index 6 and 8 modified
	var b = uuidbin()

	return ('%02x%02x%02x%02x{delimiter}%02x%02x{delimiter}%02x%02x{delimiter}%02x%02x{delimiter}%02x%02x%02x%02x%02x%02x' % [
	# low
	b[0], b[1], b[2], b[3],

	# mid
	b[4], b[5],

	# hi
	b[6], b[7],

	# clock
	b[8], b[9],

	# clock
	b[10], b[11], b[12], b[13], b[14], b[15]
  ]).format({delimiter=delimiter})

