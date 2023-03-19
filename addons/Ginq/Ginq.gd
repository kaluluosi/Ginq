extends Object
class_name Ginq

## Ginq只是个代理、或者装饰器，用来包裹数组进行各种查询运算。
## Ginq不会更改原数组的值，他只会修改原数组的克隆对象并返回该对象。

## 原始数组
var array: Array : get = getArray
var _operators = []

func _init(iterable: Array,operators:=[],lambdas:=[]):
	array = iterable.duplicate(true)
	_operators = operators
	
## 原始数组的getter
func getArray():
	return array

## 结算所有操作获取处理后的数据副本
func done()->Array:
	
	var tempValue = array
	
	# 处理链式操作
	for operator in _operators:
		tempValue = call(operator.method, operator.args, tempValue)
	
	return tempValue
	
# region


func _new_ginq(iterable:Array, operators:=[], lambdas:=[]) -> Ginq:
	return load(self.get_script().get_path()).new(iterable, operators, lambdas)

func _clone() -> Ginq:
	return _new_ginq(array, _operators.duplicate(true))	

static func eval(code:String):
	var script = GDScript.new()
	script.set_source_code("func eval():\n\treturn "+code)
	script.reload()
	var obj = RefCounted.new()
	obj.set_script(script)
	var ret = obj.eval()
	return ret

	
func register_operator(method:String, args):
	_operators.append({method=method, args=args})

# endregion

# region operator define

# 链式操作中不会直接调用处理而是将操作信息注册到操作链里
func filter(lambda: Callable) -> Ginq:
	register_operator('_filter', {lambda=lambda})
	return self

# 这才是filter操作的具体的处理函数
func _filter(args, iterable: Array) -> Array:
	var ret:Array = []
	var lambda = args.lambda
	if lambda:
		for v in iterable:
			if lambda.call(v):
				ret.push_back(v)
		return ret
	else:
		push_error('lambda not found')
		return []
		
func where(lambda:Callable) -> Ginq:
	"""
	alias of filter
	"""
	return filter(lambda)
	
func map(lambda:Callable) -> Ginq:
	var clone = _clone()
	clone.register_operator('_map', {lambda=lambda})
	return clone
	
func _map(args, iterable:Array) -> Array:
	var ret:Array = []
	var lambda = args.lambda
	if lambda:
		for v in iterable:
			var nv = lambda.call(v)
			ret.push_back(nv)
		return ret
	else:
		push_error('lambda not found')
		return []
		
func select(lambda:Callable) -> Ginq:
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

func skip_while(lambda:Callable) -> Ginq:
	var clone = _clone()
	clone.register_operator('_skip_while',{lambda=lambda})
	return clone

func _skip_while(args, iterable:Array) -> Array:
	var start_index = 0
	var lambda = args.lambda
	if lambda:
		for index in range(len(iterable)):
			if lambda.call(iterable[index]):
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
		
func take_while(lambda:Callable):
	var clone = _clone()
	clone.register_operator('_take_while', {lambda=lambda})
	return clone

func _take_while(args, iterable:Array) -> Array:
	var end_index = 0
	var lambda = args.lambda
	if lambda:
		for index in len(iterable):
			if lambda.call(iterable[index]):
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

func join(secendIterable:Array, lambda_source_key:Callable, lambda_inner_key:Callable) -> Ginq:
	var clone = _clone()
	var lambda_source_key_name = lambda_source_key
	var lambda_inner_key_name = lambda_inner_key
	clone.register_operator('_join', {lambda_source_key_name=lambda_source_key_name, lambda_inner_key_name=lambda_inner_key_name, secendIterable=secendIterable})
	return clone

func _join(args, iterable:Array) -> Array:
	var ret = []
	if args.lambda_source_key_name and args.lambda_inner_key_name:
		for v in iterable:
			var source_key_value = args.lambda_source_key_name.call(v)
			for inner in args.secendIterable:
				var inner_key_value = args.lambda_inner_key_name.call(inner)
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

func order_by(lambda:Callable = func(x): return x) -> Ginq:
	var clone = _clone()
	clone.register_operator('_order_by', {lambda=lambda})
	return clone

func _order_by(args, iterable:Array) -> Array:
	var lambda = args.lambda
	if lambda:
		var ret = []
		var temp = {}
		for v in iterable:
			var key = lambda.call(v)
			temp[key] = v

		var sorted_keys = temp.keys()
		sorted_keys.sort()
		for key in sorted_keys:
			ret.push_back(temp[key])
		
		return ret
	else:
		push_error('lambda not found')
		return iterable

func order_by_descending(lambda:Callable=func(x): return x) -> Ginq:
	var clone = _clone()
	clone.register_operator('_order_by_descending', {lambda=lambda})
	return clone

func _order_by_descending(args, iterable:Array) -> Array:
	var lambda = args.lambda
	if lambda:
		var ret = []
		var temp = {}
		for v in iterable:
			var key = lambda.call(v)
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

func all(lambda:Callable=func(x): return x) -> bool:
	var temp_array = map(lambda).done()
	var ret = true
	for value in temp_array:
		ret = ret and value
		if not ret:
			return false
	return true

func any(lambda: Callable=func(x): return x) -> bool:
	var temp_array = map(lambda).done()
	var ret = false
	for value in temp_array:
		ret = ret or value
		if ret:
			return true
	return false

func sum(lambda:Callable=func(x): return x):
	var temp_array = map(lambda).done()
	var ret = 0
	for value in temp_array:
		if typeof(value) in [TYPE_INT,TYPE_FLOAT]:
			ret += value
		else:
			push_error('{} is not number'.format({0:value}))
			return -1

	return ret

func min(lambda:Callable=func(x): return x):
	var temp_array = map(lambda).done()
	
	var min_value = temp_array.pop_front()
	for value in temp_array:
		if value < min_value:
			min_value = value

	return min_value

func max(lambda:Callable=func(x): return x):
	var temp_array = map(lambda).done()

	var max_value = temp_array.pop_front()
	for value in temp_array:
		if value > max_value:
			max_value = value

	return max_value

func average(lambda:Callable=func(x): return x):
	var temp_array = map(lambda).done()
	var tempGinq = _new_ginq(temp_array)
	var sum = tempGinq.sum()
	return sum/len(temp_array)

# end region

