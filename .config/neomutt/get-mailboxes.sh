#!/bin/sh
my_mailboxes=$(find ~/.config/neomutt/maildir/nvidia -mindepth 1 -not -name 'Inbox' -not -name 'Drafts' -not -name 'Sent Items' -not -name 'Deleted Items' -not -name cur -not -name new -not -name tmp -type d | sed 's/.*\/nvidia\///' | sort | awk '{ print "+\""$0"\""}' | tr '\n' ' ')
