To execute the container locally, please create a new integration in the https://developers.inter.co/sandbox/my-integrations download the key and cert, rename the files and put inside a folder called `config` like:

elixir-inder-sdk/
├── docker-compose.yml
├── config/
    ├── certificate.crt
    └── certificate.key

## How to release

- `git tag v0.6.0`
- `git push origin v0.6.0`
- `mix hex.user auth`
- `mix hex.publish`