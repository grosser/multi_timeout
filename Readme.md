Use multiple timeouts to soft and then hard kill a command

Install
=======

```Bash
gem install multi_timeout
```

Usage
=====

Kill command via interrupt (2) after 8 seconds and via KILL (9) after 10 seconds if that does not work
```Ruby
multi-timeout -INT 8s -KILL 10s sleep 11
multi-timeout -2 8s -9 10s sleep 11
```

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/multi_timeout.png)](https://travis-ci.org/grosser/multi_timeout)
