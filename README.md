# Moon

Library for calling Lua from Erlang, and back.  
这是个Erlang可以调用Lua和Lua回调的动态库编译工具

## Dependencies:

该动态库需要依赖部分的boost和lua源码

原作者 chaos/moon 推荐使用命令

```
ubuntu sudo apt-get install libboost1.48-all-dev liblua5.2-dev
```

基于原版制作了引导安装文件 `bootstrap.sh` ,可以辅助安装依赖库  
简易安装可以使用以下命令

like linux

```bash
./bootstrap.sh  
./rebar co
```

windows

```bash
./booststrap.sh
./vsrebar.bat
```

ps: 该命令已在基于centos, ubuntu, mac测试可用，windows版本没有做具体测试，理论上是可用的。如果必须在windows使用，请在vs手动编译  

<font size=5 color=red >ps:ps:ps:</font> 请<font size=4 color=red>不要不要不要</font>使用 `luajit` 作为lua源码，超级容易导致Erlang崩溃，别问我是怎么知道的   :joy:

如果要修改默认配置项请修改`bootstrap.sh` 与 `rebar.config`

## General usage:

Here an self-describing example of usage:

    {ok, VM} = moon:start_vm(). %% Beware! It spawns the os thread.
    {ok,{17,<<"hello">>}} = moon:eval(VM, "return 17, \"hello\"").
    ok = moon:load(VM, "priv/test.lua").
    moon:call(VM, test_function, [first_arg, <<"second_arg">>, [{key, val}, {key2, val2}]]).
    ok = moon:stop_vm(VM).

Strictly speaking, moon:stop_vm/1 is used here just for symmetry.
VM will be stopped and freed when the erlang garbage collector detects that VM become a garbage.

## Callbacks from lua to erlang:

There is two possible modes in which callbacks are handled:

#### Permissive mode
This mode allows to invoke arbitrary function from lua with erlang.call(Module, Function, Args):

    {ok, VM} = moon:start_vm().
    {ok, <<"ok">>} = moon:eval(VM, <<"return erlang.call(\"io\", \"format\", {\"Look ma, im calling! ~s~n\", {\"Yay\"}}).result">>).

Though, it is not very useful, since type mapping is far from done, and there is no way to construct atoms or strings from lua.

#### Restrictive mode
This mode passes all calls to erlang.call from lua to a single callback.
Dispatching and/or type mapping can be done here.

    Callback = fun(X) -> io:format("Callback called; args: ~p~n", [X]) end.
    {ok, VM} = moon:start_vm([{callback, Callback}]).
    {ok, <<"ok">>} = moon:eval(VM, "return erlang.call({\"hello\"}).result").

## Type mapping:

### Erlang -> Lua

<table>
  <tr>
    <th>Erlang</th>
    <th>Lua</th>
    <th>Type/Remarks</th>
  </tr>
  <tr>
    <td>nil</td>
    <td>nil</td>
    <td>nil</td>
  </tr>
  <tr>
    <td>true</td>
    <td>true</td>
    <td>boolean</td>
  </tr>
  <tr>
    <td>false</td>
    <td>false</td>
    <td>boolean</td>
  </tr>
  <tr>
    <td>42</td>
    <td>42</td>
    <td>number</td>
  </tr>
  <tr>
    <td>42.123</td>
    <td>42.123</td>
    <td>number</td>
  </tr>
  <tr>
    <td>atom</td>
    <td>"atom"</td>
    <td>string</td>
  </tr>
  <tr>
    <td>"string"</td>
    <td>{115,116,114,105,110,103}</td>
    <td>table with integers in lua, dont use it!</td>
  </tr>
  <tr>
    <td>&lt;&lt;"binary"&gt;&gt;</td>
    <td>"binary"</td>
    <td>string</td>
  </tr>
  <tr>
    <td>[]</td>
    <td>{}</td>
    <td>empty table</td>
  </tr>
  <tr>
    <td>[10, 100, &lt;&lt;"abc"&gt;&gt;]</td>
    <td>{10, 100, "abc"}</td>
    <td>array</td>
  </tr>
  <tr>
    <td>[{yet, value}, {another, value}]</td>
    <td>{yet="value", another="value"}</td>
    <td>table</td>
  </tr>
  <tr>
    <td>[{ugly, "mixed"}, list]</td>
    <td>{ugly="mixed", "list"}</td>
    <td>"list" will be accessable at index [1], and "mixed" - under the "ugly" key. No guarantees about the ordering of elements in a table</td>
  </tr>
</table>

### Lua -> Erlang

<table>
  <tr>
    <th>Lua</th>
    <th>Erlang</th>
    <th>Type/Remarks</th>
  </tr>
  <tr>
    <td>nil</td>
    <td>nil</td>
    <td>atom</td>
  </tr>
  <tr>
    <td>true</td>
    <td>true</td>
    <td>atom</td>
  </tr>
  <tr>
    <td>false</td>
    <td>false</td>
    <td>boolean</td>
  </tr>
  <tr>
    <td>42</td>
    <td>42</td>
    <td>number</td>
  </tr>
  <tr>
    <td>42.123</td>
    <td>42.123</td>
    <td>number</td>
  </tr>
  <tr>
    <td>"string"</td>
    <td>&lt;&lt;"string"&gt;&gt;</td>
    <td>binary</td>
  </tr>
  <tr>
    <td>{}</td>
    <td>[]</td>
    <td>array is a list</td>
  </tr>
  <tr>
    <td>{10, 100, "abc"}</td>
    <td>[10, 100, &lt;&lt;"abc"&gt;&gt;]</td>
    <td>array is a list</td>
  </tr>
  <tr>
    <td>{yet="value", another="value"}</td>
    <td>[{&lt;&lt;"another"&gt;&gt;, &lt;&lt;"value"&gt;&gt;}, {&lt;&lt;"yet"&gt;&gt;, &lt;&lt;"value"&gt;&gt;}]</td>
    <td>table is a proplist</td>
  </tr>
  <tr>
    <td>{ugly="mixed", "list"}</td>
    <td>[&lt;&lt;"list"&gt;&gt;, {&lt;&lt;"ugly"&gt;&gt;, &lt;&lt;"mixed"&gt;&gt;}]</td>
    <td>list with {key,value} tuples for values with keys, and plain values for the rest. No guarantees about the ordering of elements in a list</td>
  </tr>
</table>


## Todo:
* Get rid of libboost_thread dependency, and replace queue with just a mutex & condition variable
* Embed header-only part of boost to the build
* Convert erlang strings to lua strings properly
