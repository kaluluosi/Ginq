extends Object
class_name Ginq

## Ginq只是个代理、或者装饰器，用来包裹数组进行各种查询运算。
## Ginq不会更改原数组的值，他只会修改原数组的克隆对象并返回该对象。

## 原始数组
var array: Array : 
	get = getArray

## 操作链
var _operators = []
var _clone_mode:bool

## 构造函数
## iterable: Array 要包裹的数组
func _init(iterable:Array,operators:=[],clone:=false):
	array = iterable.duplicate(true)
	_operators = operators
	_clone_mode = clone
	
## 原始数组的getter
func getArray():
	return array


## eval执行字符串代码
static func eval(code:String):
	var script = GDScript.new()
	script.set_source_code("func eval():\n\treturn "+code)
	script.reload()
	var obj = RefCounted.new()
	obj.set_script(script)
	var ret = obj.eval()
	return ret

# 注册操作
func _register_operator(method:String, args) ->Ginq:
	var ginq = _clone()
	ginq._operators.append({method=method, args=args})
	return ginq
	
func _clone():
	if _clone_mode:
		return Ginq.new(array,_operators.duplicate(true),_clone_mode)
	return self

# region operator define

## 结算所有操作获取处理后的数据副本[br]
## 这个会递归处理所有链式操作返回最终处理的数组[br]
func done()->Array:
	
	var tempValue = array
	
	# 处理链式操作
	for operator in _operators:
		tempValue = call(operator.method, operator.args, tempValue)
	
	# 每次done完要清理掉操作链，避免重复使用这个Ginq对象操作残留
	_operators.clear()
	return tempValue
	


## 过滤[br]
## 将符合lambda过滤条件的元素抽取出来
## lambda:Callable[[any],bool] 过滤条件[br]
func filter(lambda: Callable) -> Ginq:
	# 链式操作中不会直接调用处理而是将操作信息注册到操作链里[br]
	return _register_operator('_filter', {lambda=lambda})

func _filter(args, iterable: Array) -> Array:
	# 这才是filter操作的具体的处理函数
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

## 同filter，只是为了保持跟linq接口一致
func where(lambda:Callable) -> Ginq:
	"""
	alias of filter
	"""
	return filter(lambda)

## 等同python的map，为每个元素应用lambda[br]
## lambda:Callable[[any],any]
func map(lambda:Callable) -> Ginq:
	return _register_operator('_map', {lambda=lambda})
	
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
		
## 等同与map，为了跟linq接口命名保持一致[br]
func select(lambda:Callable) -> Ginq:
	"""
	alias of map
	"""
	return map(lambda)

## 跳过头num个元素，返回后面的元素的数组[br]
## num:int 跳过数量
func skip(num:int) -> Ginq:
	return _register_operator('_skip', {num=num})
	
func _skip(args, iterable: Array):
	var num = args.num
	var skipnum = num if num - 1 > 0 else 0
	return iterable.slice(skipnum)
	
## 当元素符合lambda条件时跳过，遇到不符合条件时，取剩下那一半数组[br]
## lambda:Callable[[any],bool] 跳过条件
## [codeblock]
## var arr = [1,2,3,4,5,6]
## var ret = Ginq.new(arr).skip_while(func(x):x>3).done()
## >> ret = [4,5,6]
## # 当遇到4的时候条件满足，在这里截断取剩下的子数组。
## [/codeblock]
func skip_while(lambda:Callable) -> Ginq:
	return _register_operator('_skip_while',{lambda=lambda})

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

## 取头num个元素返回数组[br]
## num:int 取头数量[br]
func take(num:int) -> Ginq:
	return _register_operator('_take', {num=num})
	
func _take(args, iterable:Array) -> Array:
	var num = args.num
	if num <= 0:
		return []
	elif num > len(iterable):
		return iterable
	else:
		return iterable.slice(0, num)

## 当遇到不符合lambda判断条件的元素时截断，返回前半部分数组
## lambda:Callable[[any],bool] 跳过条件
## [codeblock]
## var arr = [1,2,3,4,5,6]
## var ret = Ginq.new(arr).skip_while(func(x):x>3).done()
## >> ret = [4,5,6]
## # 当遇到4的时候条件满足，在这里截断取剩下的子数组。
## [/codeblock]
func take_while(lambda:Callable):
	return _register_operator('_take_while', {lambda=lambda})

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

## 将两个数组合并成一对[br]
## source_key和inner_key如果值一致，那么这两个元素就合并成一对[br]
## secendIterable:Array 要合并的数组[br]
## lambda_source_key:Callable[[any],any] 返回原数组要对比的key[br]
## lambda_inner_key:Callable[[any],any]  返回目标数组要对比的key[br]
func join(secendIterable:Array, lambda_source_key:Callable, lambda_inner_key:Callable) -> Ginq:
	var lambda_source_key_name = lambda_source_key
	var lambda_inner_key_name = lambda_inner_key
	return _register_operator('_join', {lambda_source_key_name=lambda_source_key_name, lambda_inner_key_name=lambda_inner_key_name, secendIterable=secendIterable})

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

## 连接两个数组[br]
## 就是发两个数组合并成一个数组[br]
func concate(iterable:Array) -> Ginq:
	return _register_operator('_concate', {iterable=iterable})

func _concate(args, iterable:Array) -> Array:
	var target_iterable:Array = args.iterable
	var ret = iterable.duplicate(true)
	for v in target_iterable:
		ret.push_back(v)
	return ret

## 排序[br]
## lambda:Callable[[any],any] 每个元素要对比的值[br]
## comparer:Callable[[any,any],bool] 自定义对比器，不设置就默认sort[br]
func order_by(lambda:Callable = func(x): return x, comparer=null) -> Ginq:
	return _register_operator('_order_by', {lambda=lambda, comparer=comparer})

func _order_by(args, iterable:Array) -> Array:
	var lambda = args.lambda
	var comparer = args.comparer
	if lambda:
		var ret = []
		var temp = {}
		for v in iterable:
			var key = lambda.call(v)
			temp[key] = v

		var sorted_keys = temp.keys()
		
		if comparer is Callable:
			# 如果comparer有提供意味着用自定对比器
			sorted_keys.sort_custom(comparer)
		else:
			sorted_keys.sort()
			
		for key in sorted_keys:
			ret.push_back(temp[key])
		
		return ret
	else:
		push_error('lambda not found')
		return iterable

## 降序[br]
## lambda:Callable[[any],any] 每个元素要对比的值[br]
## comparer:Callable[[any,any],bool] 自定义对比器，不设置就默认sort[br]
func order_by_descending(lambda:Callable=func(x): return x,comparer=null) -> Ginq:
	return _register_operator('_order_by_descending', {lambda=lambda,comparer=comparer})

func _order_by_descending(args, iterable:Array) -> Array:
	var lambda = args.lambda
	var comparer = args.comparer
	if lambda:
		var ret = []
		var temp = {}
		for v in iterable:
			var key = lambda.call(v)
			temp[key] = v

		var sorted_keys = temp.keys()
		
		if comparer is Callable:
			# 如果comparer有提供意味着用自定对比器
			sorted_keys.sort_custom(comparer)
		else:
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

## 翻转，将数组倒转
func reverse() -> Ginq:
	return _register_operator('_reverse', null)

func _reverse(args, iterable:Array) -> Array:
	var ret = []
	for v in iterable:
		ret.push_front(v)
	return ret

## 去重
func distinct() -> Ginq:
	return _register_operator('_distinct', {})

func _distinct(args, iterable:Array) -> Array:
	var ret = []
	for v in iterable:
		if v in ret:
			continue
		else:
			ret.push_back(v)
	return ret

## 合集操作[br]
## 把两个数组合并并且取出重复取合集[br]
func union(secendIterable:Array) -> Ginq:
	return _register_operator('_union', {secendIterable=secendIterable})

func _union(args, iterable:Array) -> Array:
	# 因为利用了Ginq来做合集操作，所以需要用新的Ginq对象
	var ret = Ginq.new(iterable).concate(args.secendIterable).distinct().done()
	return ret

## 交集操作[br]
## 把两个数组相同元素抽取出来返回数组[br]
func intersect(secendIterable:Array) -> Ginq:
	return _register_operator('_intersect', {secendIterable=secendIterable})

func _intersect(args, iterable:Array) -> Array:
	var ret = []
	for v in iterable:
		if v in args.secendIterable:
			ret.push_back(v)
	return ret

## 异或操作[br]
## 将两个数组不同部分抽取出来返回数组[br]
func expect(secendIterable:Array) -> Ginq:
	return _register_operator('_expect', {secendIterable=secendIterable})

func _expect(args, iterable:Array) -> Array:
	var ret = []
	iterable = Ginq.new(iterable).concate(args.secendIterable).done()
	for v in iterable:
		if v in ret:
			var index = ret.find(v)
			ret.remove_at(index)
			continue
		else:
			ret.push_back(v)
		
	return ret

## 结算操作-全部[br]
## 判断是否所有元素都符合lambda条件[br]
## lambda:Callable[[any],bool] 判断条件[br]
func all(lambda:Callable=func(x): return x) -> bool:
	var temp_array = map(lambda).done()
	var ret = true
	for value in temp_array:
		ret = ret and value
		if not ret:
			return false
	return true

## 结算操作-任何[br]
## 判断是否有一个元素符合lambda条件[br]
## lambda:Callable[[any],bool] 判断条件[br]
func any(lambda: Callable=func(x): return x) -> bool:
	var temp_array = map(lambda).done()
	var ret = false
	for value in temp_array:
		ret = ret or value
		if ret:
			return true
	return false

## 结算操作-求和[br]
## 将数组里每个元素用lambda表达式运算返回的值求和[br]
## lambda:Callable[[any],int|float] 用于每个元素返回求和数值[br]
## [color=yellow]Warning:[/color] lambda返回的必须是数字[br]
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

## 结算操作-取最小值[br]
## 将数组里每个元素用lambda表达式运算返回的值作比较，取最小值的按个元素[br]
func min(lambda:Callable=func(x): return x):
	var temp_array = map(lambda).done()
	
	var min_value = temp_array.pop_front()
	for value in temp_array:
		if value < min_value:
			min_value = value

	return min_value

## 结算操作-取最小值[br]
## 将数组里每个元素用lambda表达式运算返回的值作比较，取最大值的按个元素[br]
func max(lambda:Callable=func(x): return x):
	var temp_array = map(lambda).done()

	var max_value = temp_array.pop_front()
	for value in temp_array:
		if value > max_value:
			max_value = value

	return max_value

## 结算操作-取最小值[br]
## 将数组里每个元素用lambda表达式运算返回的值求和并取平均值[br]
func average(lambda:Callable=func(x): return x):
	var temp_array = map(lambda).done()
	var tempGinq = Ginq.new(temp_array)
	var sum = tempGinq.sum()
	return sum/len(temp_array)

# end region

