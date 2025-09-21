# SearchMerge

SearchMerge is a toy project built to learn modern Perl. It's a very simple web search engine.
Given a query, it fetches results from multiple sources, merges them, parses and ranks them, and then exposes the results through both a CLI and a simple web server.

This is not production-ready software, it exists mainly for fun, experiments, and practicing Perl patterns.
---

## Project Structure

```
.
├── cpanfile                  # Declares dependencies
├── lib/SearchMerge           # Core modules
│   ├── Aggregator.pm         # Collects results from multiple sources
│   ├── Cache.pm              # Simple caching layer
│   ├── Parser.pm             # Parses responses into a common format
│   ├── Ranker.pm             # Ranks results
│   ├── RateLimiter/          # Rate limiting strategies
│   │   ├── MinimumInterval.pm
│   │   └── TokenBucket.pm
│   ├── Role/RateLimiter.pm   # Role shared by rate limiter implementations
│   └── Web.pm                # Mojolicious app for a web interface
├── script/
│   ├── cli.pl                # Command-line interface
│   └── server.pl             # Starts the web server
└── t/                        # Unit tests
    ├── cache.t
    ├── parser.t
    └── ranker.t
```

---

## Running

### Install dependencies

```bash
cpanm --installdeps .
```

### Run CLI

```bash
perl script/cli.pl "search query"
```

### Run Web Server

```bash
perl script/server.pl daemon
curl "http://localhost:3000/search?q=search%20query"
```

---

## Features

* Aggregator: pulls from multiple predefined sources
* Parser: normalizes source results
* Ranker: orders results based on simple heuristics
* Cache: avoids re-fetching repeated queries
* Rate Limiting: two strategies implemented to learn dependency injection (minimum interval, token bucket)
* Web & CLI frontends
* Tests: basic unit tests for cache, parser, and ranker

---

