function compile {
  echo "$1" | bin/trial-c > tmp/test.s
  if [ $? -ne 0 ]; then
    echo "Failed to compile $2"
    exit
  fi
  gcc -o bin/test src/driver.c tmp/test.s
  if [ $? -ne 0 ]; then
    echo "GCC failed: $1"
    exit
  fi
}

function assertequal {
  if [ "$1" != "$2" ]; then
    echo "Test failed: $2 expected but got $1"
    exit
  else
    printf "."
  fi
}

function testastf {
  result="$(echo "$2" | bin/trial-c -a)"
  if [ $? -ne 0 ]; then
    echo "Failed to compile $2"
    exit
  fi
  assertequal "$result" "$1"
}

function testast {
  testastf "$1" "int f(){$2}"
}

function testf {
  compile "$2"
  assertequal "$(bin/test)" "$1"
}

function test {
  testf "$1" "int f(){$2}"
}

function testfail {
  expr="int f() {$1}"
  echo "$expr" | bin/trial-c > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Should fail to compile, but succeded: $expr"
    exit
  fi
}

testast '(int)f(){1;}' '1;'
testast '(int)f(){(+ (- (+ 1 2) 3) 4);}' '1+2-3+4;'
testast '(int)f(){(+ (+ 1 (* 2 3)) 4);}' '1+2*3+4;'
testast '(int)f(){(+ (* 1 2) (* 3 4));}' '1*2+3*4;'
testast '(int)f(){(+ (/ 4 2) (/ 6 3));}' '4/2+6/3;'
testast '(int)f(){(/ (/ 24 2) 4);}' '24/2/4;'
testast '(int)f(){(decl int a 3);}' 'int a=3;'
testast "(int)f(){(decl char c 'a');}" "char c = 'a';"
testast '(int)f(){(decl char* s "abc");}' 'char *s="abc";'
testast '(int)f(){(decl char[4] s "abc");}' 'char s[4]="abc";'
testast '(int)f(){(decl int[3] a {1,2,3});}' 'int a[3]={1,2,3};'
testast '(int)f(){(decl int a 1);(decl int b 2);(= a (= b 3));}' 'int a=1;int b=2;a=b=3;'
testast '(int)f(){(decl int a 3);(& a);}' 'int a=3;&a;'
testast '(int)f(){(decl int a 3);(* (& a));}' 'int a=3;*&a;'
testast '(int)f(){(decl int a 3);(decl int* b (& a));(* b);}' 'int a=3;int *b=&a;*b;'
testast '(int)f(){(for (decl int a 1) 3 7 {5;});}' 'for(int a=1;3;7){5;}'
testast '(int)f(){"abc";}' '"abc";'
testast "(int)f(){'c';}" "'c';"
testast '(int)f(){(int)a();}' 'a();'
testast '(int)f(){(int)a(1,2,3,4,5);}' 'a(1,2,3,4,5);'

test 0 '0;'

test 3 '1+2;'
test 3 '1 + 2;'
test 10 '1+2+3+4;'
test 11 '1+2*3+4;'
test 14 '1*2+3*4;'
test 4 '4/2+6/3;'
test 3 '24/2/4;'

test 98 "'a' + 1;"

test 2 '1;2;'

test 1 '1<2;'
test 0 '1>2;'

test 3 'int a=1;a+2;'
test 102 'int a=1;int b=48+2;int c=a+b;c*2;'
test 55 'int a[1]={55};int *b=a;*b;'
test 67 'int a[2]={55,67};int *b=a+1;*b;'
test 30 'int a[]={20,30,40};int *b=a+1;*b;'

test a3 'printf("a");3;'
test abc5 'printf("%s", "abc");5;'
test b1 "printf(\"%c\", 'a'+1);1;"

test 61 'int a=61; int *b=&a;*b;'
test 97 'char *c="ab";*c;'
test 98 'char *c="ab"+1;*c;'
test 99 'char s[4]="abc";char *c=s+2;*c;'

test 'a1' 'if(1){printf("a");}1;'
test '1' 'if(0){printf("a");}1;'
test 'x1' 'if(1){printf("x");}else{printf("y");}1;'
test 'y1' 'if(0){printf("x");}else{printf("y");}1;'

test 012340 'for(int i=0; i<5; i=i+1){printf("%d", i);}0;'

testf '102' 'int f(int n){n;}'
testf 77 'int g(){77;} int f(){g();}'
testf 79 'int g(int a){a;} int f(){g(79);}'
testf 21 'int g(int a,int b,int c,int d,int e,int f){a+b+c+d+e+f;} int f(){g(1,2,3,4,5,6);}'
testf 79 'int g(int a){a;} int f(){g(79);}'
testf 98 'int g(int *p){*p;} int f(){int a[1]={98};g(a);}'

testfail '0abc;'
testfail '1+;'
testfail 'a=1'
testfail '1=2'

testfail '&"a";'
testfail '&1;'
testfail '&a();'

echo
echo "All tests passed."
