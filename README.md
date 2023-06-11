# fly-lemmy

Scripting and configuration for a Lemmy instance inside Fly.io.

## How do I use this?

You need to sign up for a fly.io account. You'll also need an SMTP server
which fly.io does not really help with -- I use Amazon SES, but you
could go for Sendgrid or Mailgun or whatever you desire.

## Config

Copy `.env.example` to `.env` and fill in all the environment variables.

## Running

Use `./start.sh`. All your containers should come online and connect
properly to each other. The command should should be idempotent, so if you run
into an error or want to run it again just do so.

## Cost

I think less than $10/mo, maybe even less than that? Will report back when I figure it out.
