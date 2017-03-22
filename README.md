# memorobot

This IRC bot stores and recalls snippets of text. Can be used to bookmark stuff, as a dictionary, or whatever.

----

## Usage

```bash
$ perl memorobot.pl <server> <port> <nickname> "<#channel1,#channel2,#etc>" [./path/to/obey.tsv] [./path/to/dict.tsv]
```

This shell script will run the bot, connect to Freenode, and listen for mentions in `#angularjs`: 

```bash
#!/bin/bash
perl ./memorobot.pl chat.freenode.org 6665 memorobot "#angularjs" ./obey.tsv ./dict.tsv
```

Once the bot joined a channel, it starts listening for mentions, reads a keyword if provided, and recalls a snippet associated with said keyword:

```
<some_user> memorobot: currencies
<memorobot> https://en.wikipedia.org/wiki/List_of_currencies
<some_user> memorobot: @remove currencies
<memorobot> You are not my supervisor
```

If a nickname provided, the result will be forwarded to it:

```
<some_user> Semantic UI is semantic!
<AnotherUser> memorobot: semantic-ui some_user
<memorobot> some_user: No, it isn't - https://news.ycombinator.com/item?id=6381220
```

---

## obey.tsv

A list of nicknames allowed to use supervisor commands.

```tsv
WhatTheDilly
```
This will allow the user `WhatTheDilly` to use supervisor commands:

---

## dict.tsv

List of snippets in [TSV format](https://en.wikipedia.org/wiki/Tab-separated_values). This example contains some Wikipedia links:

```tsv
record-labels	https://en.wikipedia.org/wiki/List_of_record_labels
currencies	https://en.wikipedia.org/wiki/List_of_currencies
colors	https://en.wikipedia.org/wiki/List_of_colors_(compact)
```

---

## Supervisor commands

These commands only can be executed by the nicknames listed in `obey.tsv`.

### `@add <term> <text>`

Add new snippet. The `term` is a single word by addressing which the `text` gets recalled.

### `@remove <term>`

Remove a snippet associated with `term`.

### `@update <term> <text>`

Update snippet's text.

### `@obey <nickname>`

Allow `nickname` to execute supervisor commands.

### `@disobey <nickname>`

Remove `nickname` from `obey.tsv`, meaning `nickname` cannot use supervisor commands anymore.

---

## User commands

These commands can be executed by anyone.

### `!list [first letter(s)]`

Lists terms that match the pattern. If no pattern provided, and there aren't too many memos, dumps all it got.

### `!help`

Links this repo.
