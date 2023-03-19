# Ginq
Linq for GDScript and Lambda wrapper

## How to use Ginq

The lambda text is Python style.

```
	var l:Ginq = Ginq.new([1,1,2,3])
	var ret = l.filter("lambda x: x==1").done()
  
```

Ginq also surpose chain calling.

```
var l:Ginq = Ginq.new([1,1,2,3])
var ret = l.filter("lambda x: x>1").skip(1).take(1).done()
# ret: [3]
```

## Unit test
addons/gut is not necessary, you can remove it.
I use gut to make unit test for Ginq.

