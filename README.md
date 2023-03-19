# Ginq
Linq for GDScript 2.0

## How to use Ginq

```
    var l:Ginq = Ginq.new([1,1,2,3])
    var ret = l.filter(func(x):return x>1).done()
    print(ret)
    # >>  [2,3]

```

Ginq also surpose chain calling.

```
    # you can chain it just like linq
    var ret2 = l.filter(func(x): return x>1).map(func(x): return x*2).done()
    print(ret)
    # >> [4,6]
```

## Unit test
addons/gut is not necessary, you can remove it.
I use gut to make unit test for Ginq.

