# The Profound Kernel

The Profound Kernel is a really, really obnoxious twitter bot. You can follow @ProfoundKernel on twitter.

# What it does

The Profound Kernel (herein after referred to as PK) scours twitter for mentions of the phrase **'deep seeded'**. It then, after running through a number of rules, corrects the user by replying to them saying, "@user - I think you mean deep-seated."

So yeah - totally obnoxious.

## Rules

Whilst the PK is obnoxious, I don't want it to be impolite or stupid - therefore it complies to the following rules:

1. It will not correct a user that has been previously corrected in the last 3 weeks.
2. I will not correct a user retweeting someone else's mistaken use of deep-seated.
3. It will not correct an already corrected tweet.
4. It will not correct a tweet that mentions a previous offender.
5. It will not correct a tweet that already has the correct phrase in it as well.
6. It will not correct Proper Noun versions of Deep Seeded. Turns out, there's a farm called Deep Seeded Community Farm. Clever.

# Why

I'm a grammar nazi. Simple as that. I'm at once both intrigued and disgusted with the way the English language is mutating, and this is my admittedly tiny way of fighting back.

I also wanted to play around with some interesting patterns and technologies, namely, 

1. redis, and namespacing redis data (which turned out to be quite simple).
2. The block configuration pattern. Super handy.
3. Twitter's API, and oauth
4. And, lastly, running pure non-web ruby apps on heroku.

# Upcoming

I plan to generalise this into a reusable gem, so some enterprising soul (probably me), can unleash an army of grammar nazis onto twitter.

# Thanks

Many thanks to the following people:

1. [Ché Nxusani](https://github.com/codefendant) for the pairing sessions, and nagging me to complete it.
2. [Kevin McKelvin](https://github.com/kmckelvin) for some tips on paring down the initial search results.
3. And of course, the biggest thanks goes to [Stealth Mountain](https://twitter.com/StealthMountain) for planting the seed, or should I say kernel, for this project ;)
