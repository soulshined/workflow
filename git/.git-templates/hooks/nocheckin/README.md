This hook will not allow any file to be committed if the tag '@NOCHECKIN' is found. \[case-sensitive, and requires a space prefix or start of line]

The tag is language/file/or location agnostic; as long as it is in the file somewhere it will not be committed. 

This can be useful for changing `.pom` files or configs you need for local purposes but don't want to include with a push or pr. 

This allows for `git add .` convenience. 

> Note: This does not short-circuit, if tag is found it omits the file from commit, does not exit and continues the commit

> This hook will be honored even with `--force`.

### Example

<pre>
<code data-language="java">//&nbsp;@NOCHECKIN
// TODO: create wrapper or builder pattern
public class Foo {

}</code></pre>

### When committed, something similar to the following will display for each file:
```
WARNING: .src/main/java/com/sfg/ent/Foo.java contains the '@NOCHECKIN' flag

[master (root-commit) a5a124f] Hello. World
 17 files changed, 652 insertions(+)
 ...
 ...
 ...
```