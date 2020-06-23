*Disclaimer: This is just something I threw together over a couple lunch breaks*

# Purpose
Many IRC channels are setting up bots to bridge their chat to Discord. There are many users of IRC who are very
uncomfortable over Discord's privacy policy, including myself. When a channel is bridged there are only two
options: Supply Discord with your data, or leave the channel.

This bot attempts to provide a third option by acting as an anonymity device, partially shielding users from
Discord's data gathering.

# Functionality
Our functionality is extremely simple: Bridge two IRC channels on the same server.. But with a twist! Users in
the discord-infected channel see only pseudonyms of the users in the privacy channel. These pseudonyms rotate
regularly.

This shields people's nicks, hostnames, etc from Discord. This is not foolproof. Obviously one still has to be
careful about what you type, and especially what URLs are shared! Additionally, Discord may be using ML to analyze
text patterns in such a way that could easily de-anonymize the user.

This is pretty useless if there is only one user in the privacy channel. There need to be multiple users.

# Install/Use
Install cpanminus via your distro's package manager. Run: cpanm AnyEvent::IRC. Edit the .pl script. Run the .pl
script.

Best ran in a tmux session under a loop: ```while true: do ./plinkbot.pl; sleep 10; done```

