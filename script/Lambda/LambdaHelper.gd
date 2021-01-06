extends Node

static func f(lambda:String):
	var _lambda = preload("res://script/Lambda/Lambda.gd")
	return _lambda.new(lambda)

static func sayhello():
	print('hello')
