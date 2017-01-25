DEPRECATED use nested timeout instead `timeout -t 20 -s KILL timeout -t 15 -s INT something-slow` .. eats 5m less ram

Use multiple timeouts to soft and then hard kill a command

Install
=======

```Bash
gem install multi_timeout
```

or as standalone binary (needs any ruby)

```Bash
curl https://rubinjam.herokuapp.com/pack/multi_timeout > multi-timeout && chmod +x multi-timeout
```

Usage
=====

Kill command via interrupt (2) after 8 seconds and via KILL (9) after 10 seconds if that does not work
```Ruby
multi-timeout -INT 8s -KILL 10s sleep 11
multi-timeout -2 8s -9 10s sleep 11
```

Or call from ruby:

```
MultiTimeout.run("sleep 5", timeouts: {INT: 10, KILL: 20}) # term after 10s and kill after 20s
MultiTimeout.run(["sleep", "5"], ...) # alertnate call with safer arrays
```

Unix timeout
===========
nesting timeout does not work:
`timeout -s9 2 timeout -s2 1 sh -c 'ruby -e "Signal.trap(2){puts %{xxx}}; sleep 1.4; puts %{aaa}; sleep 1; puts %{oops}"'`

if you just need multiple kill signals you can do:
`timeout -k 4s 5s sleep 10`

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/multi_timeout.png)](https://travis-ci.org/grosser/multi_timeout)
