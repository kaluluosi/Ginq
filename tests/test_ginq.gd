extends GutTest
var L = Ginq

func test_filter():
	var l:Ginq = L.new([1,1,2,3])
	var ret = l.filter("lambda x: x==1").done()
	assert_eq(ret, [1,1], 'not match')

func test_map():
	var l:Ginq = L.new([1,1,2,3])
	var ret = l.map("lambda x:x*2").done()
	assert_eq(ret, [2,2,4,6], 'not match')

func _skip_params():
	var params = [
		['array', 'skip', 'expect'],
		[
			[[1,1,2,3],2,[2,3]],
			[[1,1,2,3],1,[1,1,2,3]],
			[[1,1,2,3],0,[1,1,2,3]],
			[[1,1,2,3],5,[]]
		]
	]

	return ParameterFactory.named_parameters(params[0], params[1])

func test_skip(params=use_parameters(_skip_params())):
	var l:Ginq = L.new(params.array)
	var ret = l.skip(params.skip).done()
	assert_eq(ret, params.expect, 'not match')

func _skip_while_params():
	var params = [
		['array', 'lambda', 'expect'],
		[
			[[1,1,2,3], "lambda x:x<2", [2,3]],
			[[1,1,2,3], "lambda x:x>2", [1,1,2,3]],
		]
	]
	return ParameterFactory.named_parameters(params[0], params[1])

func test_skip_while(params=use_parameters(_skip_while_params())):
	var l:Ginq = L.new(params.array)
	var ret = l.skip_while(params.lambda).done()
	assert_eq(ret, params.expect, 'not match')


func _take_params():
	var params = [
		['array', 'take', 'expect'],
		[
			[[1,1,2,3], 2, [1,1]],
			[[1,1,2,3], 0, []],
			[[1,1,2,3], 5, [1,1,2,3]]
		]
	]
	return ParameterFactory.named_parameters(params[0], params[1])


func test_take(params=use_parameters(_take_params())):
	var l:Ginq = L.new(params.array)
	var ret = l.take(params.take).done()
	assert_eq(ret, params.expect, 'not match')


func _take_while_params():
	var params = [
		['array', 'lambda', 'expect'],
		[
			[[1,1,2,3], 'lambda x:x<2', [1,1]],
			[[1,1,2,3], 'lambda x:x>2', []],
			[[1,1,2,3], 'lambda x:x>0', [1,1,2,3]],
		]
	]

	return ParameterFactory.named_parameters(params[0], params[1])

func test_take_while(params=use_parameters(_take_while_params())):
	var l:Ginq = L.new(params.array)
	var ret = l.take_while(params.lambda).done()
	assert_eq(ret, params.expect, 'not match')


func test_join():
	var left = [
		{id=1, name='a'}, {id=2,name='b'}
	]
	var right = [
		{id=1, age=1}, {id=2,age=2}
	]

	var left_ginq:Ginq = L.new(left)
	var ret = left_ginq.join(right, "lambda x:x.id", "lambda y:y.id").done()

	assert_eq(ret[0][0].id, ret[0][1].id, 'not match')
	assert_eq(ret[1][0].id, ret[1][1].id, 'not match')

	ret = left_ginq.join(right, "lambda x:x.id", "lambda y:y.id").select("lambda pair: {id=pair[0].id, name=pair[0].name, age=pair[1].age}").done()
	assert_eq(ret[0].id,1, 'not match')
	assert_eq(ret[0].name,'a', 'not match')
	assert_eq(ret[0].age,1, 'not match')


func test_concate():
	var left = [1,2,3]
	var right = [4,5,6]

	var left_ginq = L.new(left)
	var ret = left_ginq.concate(right).done()
	assert_eq(ret, [1,2,3,4,5,6], 'not match')


func test_order():
	var unorder = [2,3,1,4,5]
	var order_ginq = L.new(unorder)
	var ret = order_ginq.order_by().done()
	assert_eq(ret, [1,2,3,4,5], 'not match')

func test_order_by_lambda():
	var unorder_obj_list = [
		{id=2, name='b'},
		{id=1, name='a'},
		{id=4, name='c'},
		{id=3, name='d'},
	]

	var order_obj_list = L.new(unorder_obj_list)
	var ordered_obj_list = order_obj_list.order_by("lambda x:x.name").done()
	var name_list = L.new(ordered_obj_list).map("lambda x:x.name").done()
	assert_eq(name_list, ['a','b','c','d'], 'not match')

	ordered_obj_list = order_obj_list.order_by("lambda x:x.id").done()
	var id_list = L.new(ordered_obj_list).map("lambda x:x.id").done()
	assert_eq(id_list, [1,2,3,4], "not match")
	
func test_order_descending():
	var unorder = [2,3,1,4,5]
	var order_ginq = L.new(unorder)
	var ret = order_ginq.order_by_descending().done()
	assert_eq(ret, [5,4,3,2,1], 'not match')

func test_order_by_lambda_descending():
	var unorder_obj_list = [
		{id=2, name='b'},
		{id=1, name='a'},
		{id=4, name='c'},
		{id=3, name='d'},
	]

	var order_obj_list = L.new(unorder_obj_list)
	var ordered_obj_list = order_obj_list.order_by_descending("lambda x:x.name").done()
	var name_list = L.new(ordered_obj_list).map("lambda x:x.name").done()
	assert_eq(name_list, ['d','c','b','a'], 'not match')

	ordered_obj_list = order_obj_list.order_by_descending("lambda x:x.id").done()
	var id_list = L.new(ordered_obj_list).map("lambda x:x.id").done()
	assert_eq(id_list, [4,3,2,1], "not match")
	
func test_reverse():
	var array = [1,2,3,4,5]
	var ret = L.new(array).reverse().done()
	assert_eq(ret, [5,4,3,2,1],'not match')

func test_distinct():
	var array = [1,2,3,3,4,5,6,5]
	var ret = L.new(array).distinct().done()
	assert_eq(ret, [1,2,3,4,5,6], 'not match')


func test_union():
	var left = [1,2,3]
	var right = [3,4,5]

	var left_ginq = L.new(left)
	var ret = left_ginq.union(right).done()
	assert_eq(ret, [1,2,3,4,5], 'not match')

func test_intersect():
	var left = [1,2,3]
	var right = [3,4,5]

	var left_ginq = L.new(left)
	var ret = left_ginq.intersect(right).done()
	assert_eq(ret, [3], 'not match')

func test_expect():
	var left = [1,2,3]
	var right = [3,4,5]

	var left_ginq = L.new(left)
	var ret = left_ginq.expect(right).done()
	assert_eq(ret, [1,2,4,5], 'not match')


func test_all():
	var array = [1,2,3,4]
	var ginq = L.new(array)

	var ret = ginq.all()
	assert_eq(ret, true, 'not match')

	array = [1,2,null, 4]
	ginq = L.new(array)

	ret = ginq.all()
	assert_eq(ret, false, 'not match')

	array = [
			{
				id=1,
				name='a'
			},
			{
				id=2,
				name=null
			}
		]
	ginq = L.new(array)

	ret = ginq.all("lambda x: x.name")
	assert_eq(ret, false, 'not match')

func test_any():
	var array = [1,2,null,4]
	var ginq = L.new(array)

	var ret = ginq.any()
	assert_eq(ret, true, 'not match')

	array = [null, null]
	ginq = L.new(array)

	ret = ginq.any()
	assert_eq(ret, false, 'not match')

	array = [
			{
				id=1,
				name='a'
			},
			{
				id=2,
				name=null
			}
		]
	ginq = L.new(array)

	ret = ginq.any("lambda x: x.name")
	assert_eq(ret, true, 'not match')

func test_sum():
	var array = [1,1,1,1]
	var ginq = L.new(array)
	var ret = ginq.sum()
	assert_eq(ret, 4)

	array = [
		{
			age=1
		},
		{
			age=2
		}
	]

	ginq = L.new(array)
	ret = ginq.sum("lambda x:x.age")
	assert_eq(ret, 3)

func test_min():
	var array = [1,2,3,4]
	var ginq = L.new(array)
	var ret = ginq.min()
	assert_eq(ret, 1)

	array = [
		{
			age=1
		},
		{
			age=2
		}
	]

	ginq = L.new(array)
	ret = ginq.min("lambda x:x.age")
	assert_eq(ret, 1)


func test_max():
	var array = [1,2,3,4]
	var ginq = L.new(array)
	var ret = ginq.max()
	assert_eq(ret, 4)

	array = [
		{
			age=1
		},
		{
			age=2
		}
	]

	ginq = L.new(array)
	ret = ginq.max("lambda x:x.age")
	assert_eq(ret, 2)

func test_average():
	var array =  [1,2,3]
	var ginq = L.new(array)
	var ret = ginq.average()
	assert_eq(ret, 2)

	array = [
		{
			age=1
		},
		{
			age=2
		},
		{
			age=3
		}
	]

	ginq = L.new(array)
	ret = ginq.average("lambda x:x.age")
	assert_eq(ret, 2)
