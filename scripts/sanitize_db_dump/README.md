# DB Dump Sanitizer

Sanitizes a DB dump of the T-Alerts database produced from `pg_dump`, using
some simple regexes.

Things that are scrubbed:
- emails
- phone numbers

This was successfully used to dump and restore a scrubbed copy of the
production database on 27 July 2022.

This is mostly a port of `scripts/sanitize_db_dump.exs` (which currently
has a massive memory leak), which also catches a few more places where
phone numbers or emails are present.

## Example Usage
Input is read line-by-line over `stdin`, thus this should be used as part
of a shell pipeline.

```
pg_dump <...> | cargo run > out.dump
```

or

```
pg_dump <...> | sanitize_db_dump > out.dump
```

Note: you probably want to pipe the output through some sort of
compression tool like `gzip` as the resulting file is very large (~35GB)
uncompressed.

## IMPORTANT: Implementation Notes
The current implementation is strongly coupled to the structure of the DB
dump produced by the current version of `pg_dump`. For example, phone
numbers (10-digit strings) always come after an email (which are easier to
detect by regex), and this knowledge is used to avoid scrubbing other
10-digit strings that are not phone numbers.


## Building a portable binary
You can build a binary backed by musl libc which can be deployed on an AWS
EC2 instance.

```
rustup target add x86_64-unknown-linux-musl
cargo build --release --target=x86_64-unknown-linux-musl
```

The resulting binary will be in the `./target/x86_64-unknown-linux-musl`
directory.

More information about Rust platform support is available at:
https://doc.rust-lang.org/nightly/rustc/platform-support.html

## Other Notes
- (Nick) When I was attempting to restore a dump produced by this tool
  locally, I needed first to `gunzip` the compressed dump to a file
  on-disk, rather than piping directly to `psql`, as it was choking for
  some reason.
