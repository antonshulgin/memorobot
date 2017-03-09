# memorobot

IRC bot that stores and recalls snippets of text. Can be used to bookmark stuff, as a dictionary, or whatever.

## Usage

```bash
$ perl memorobot.pl <server> <port> <nickname> "<#channel1,#channel2,#etc>" [./path/to/obey.tsv] [./path/to/dict.tsv]
```

This shell script will run the bot, connect to Freenode, and listen for mentions in `#angularjs`: 

```bash
#!/bin/bash

perl ./memorobot.pl chat.freenode.org 6665 memorobot "#angularjs" ./obey.tsv ./dict.tsv
```

Once the bot joins a channel, it listens for mentions, reads a keyword if provided, and recalls a snippet associated with said keyword:

```
<some_user> memorobot: currencies
<memorobot> https://en.wikipedia.org/wiki/List_of_currencies
<some_user> memorobot: @remove currencies
<memorobot> You are not my supervisor
```

## obey.tsv

A list of nicknames allowed to use commands.

### Example

This will allow the user `WhatTheDilly` to use commands:

```tsv
WhatTheDilly
```

## dict.tsv

List of snippets in [TSV format](https://en.wikipedia.org/wiki/Tab-separated_values).

### Example

This dictionary contains some Wikipedia links:

```tsv
record-labels	https://en.wikipedia.org/wiki/List_of_record_labels
currencies	https://en.wikipedia.org/wiki/List_of_currencies
colors	https://en.wikipedia.org/wiki/List_of_colors_(compact)
```

## Commands

### `@add <term> <text>`

Add new snippet. The `term` is a single word by addressing which the `text` gets recalled.

### `@remove <term>`

Remove a snippet associated with `term`.

### `@update <term> <text>`

Soon.

### `@obey <nickname>`

Allow `nickname` to execute commands.

### `@disobey <nickname>`

Remove `nickname` from `obey.tsv`, meaning `nickname` cannot use commands anymore.
