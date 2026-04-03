# src-report

I pronounce "src" as "cirque", and I like how this tool sounds like "surf
report".

Run this command to get a report on the status of my `~/src` directory. The
idea is to know if I have any uncommitted/unpushed changes that I'd regret
losing.

In other words: "can I throw my laptop in the ocean?"

This stitches together a couple of projects:

- <https://github.com/jfly/treeport>: to walk the filesystem and build a report
- <https://github.com/jfly/devshell-init>: to detect if I can recreate the project's devshells

## How I use this

This tool is fast, but not instantaneous, so I store the results in a tempfile.
I do my analysis in [`nushell`](https://www.nushell.sh/), so I massage some
datatypes into native nushell types, as well.

```console
src-report | from csv | update "size (bytes)" { |row| if ($in | is-empty) { "" } else { $in | into filesize  } } | rename --column { "size (bytes)": size } | to nuon o> /tmp/src-report.nuon
```

(Is there a better way to conditionally parse a column in nushell?)

View the cleanup work remaining:

```console
open /tmp/src-report.nuon | where status != synced | sort-by category status size
```
