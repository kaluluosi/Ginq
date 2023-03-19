extends GutTest

func test_lambda():
	var oneparam = Lambda.new("lambda x:x+1")
	var ret = oneparam.invoke([1])
	assert_eq(ret,2)

	var towparams = Lambda.new("lambda x,y: x+y")
	ret = towparams.invoke([1,2])
	assert_eq(ret,3)
