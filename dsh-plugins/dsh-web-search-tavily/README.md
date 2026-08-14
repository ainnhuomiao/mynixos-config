# dsh-web-search-tavily

[Tavily](https://tavily.com)-backed `WebSearchProvider` for the DeepSeek Harness
[`ctx.web`](https://github.com/deepseek-ai/deepseek-harness) seam. Calls
`POST https://api.tavily.com/search` and maps Tavily `results[]` into the
seam's normalized `WebSearchResult`. Provider-generated `answer` prose is not
trusted as `content`.

## Install (web profile)

```sh
# 从仓库根目录执行;file: 路径用 $(pwd) 展开,避免硬编码用户名/绝对路径
cd /path/to/mynixos-config
dsh plugin --profile web add "file:$(pwd)/dsh-plugins/dsh-web-search-tavily"
```

Then register the row and select the provider in
`~/.dsh/profiles/web/cordis.patch.yml`:

```yaml
- insert:
    - id: web-search-tavily
      name: "dsh-web-search-tavily"
      config:
        apiKeyEnv: TAVILY_API_KEY

- id: web
  config:
    searchProvider: tavily
```

Restart the profile. Credentials resolve per search from
`~/.dsh/.credentials.yaml` (`TAVILY_API_KEY: tvly-...`), the launching
environment, or a literal `apiKey` in the `web-search-tavily` settings
section.

## Config

| Key           | Default                  | Meaning                                                     |
| ------------- | ------------------------ | ----------------------------------------------------------- |
| `apiKey`      | unset                    | Literal Tavily API key (secret; prefer `apiKeyEnv`)         |
| `apiKeyEnv`   | `TAVILY_API_KEY`         | Credential reference resolved per search                    |
| `baseURL`     | `https://api.tavily.com` | API base; `/search` is appended                             |
| `searchDepth` | `basic`                  | `basic` or `advanced` (Tavily search depth)                 |
| `maxResults`  | `5`                      | Upstream `max_results` (clamped: 1-10 basic, 1-20 advanced) |
