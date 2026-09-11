---
title: Typography Showcase
date: 2026-09-11 10:00:00 +0530
categories: [Design]
tags: [typography, showcase]
description: A test post showing how Cause and Cascadia Code look with various elements.
published: false
---

This is an example post to showcase the **Cause** font and **Cascadia Code** monospace font across various content types.

## Inline Code

Here's some text with `inline code` and **bold text** mixed together to see how the weight and fonts render side by side.

## Python

```python
def fibonacci(n: int) -> int:
    """Return the nth Fibonacci number."""
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b

# Print the first 10 numbers
for i in range(10):
    print(f"F({i}) = {fibonacci(i)}")
```

## JavaScript / TypeScript

```typescript
interface Post {
  title: string;
  date: Date;
  tags: string[];
}

function createPost(title: string, tags: string[]): Post {
  return {
    title,
    date: new Date(),
    tags,
  };
}

const post = createPost("Hello World", ["intro", "typography"]);
```

## Bash

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Building site..."
bundle exec jekyll build --production

echo "Deploying..."
rsync -avz --delete _site/ user@server:/var/www/
```

## Ordered List

1. First item with **bold** and `code`
2. Second item with a [link](https://example.com)
3. Third item with *italic* text
4. Fourth item — just a regular line to show weight consistency

## Unordered List

- All items render in Cause at the same weight
- Even nested lists look consistent
  - Like this indented one
  - And this one too

## Blockquote

> "Typography is the craft of endowing human language with a durable visual form, and thus with an independent existence."
> — Robert Bringhurst, *The Elements of Typographic Style*

## Table

| Element         | Font       | Weight (Light) | Weight (Dark) |
|-----------------|------------|----------------|---------------|
| Body text       | Cause      | 500            | 600           |
| Headings        | Cause      | 500            | 600           |
| Inline code     | Cascadia Code  | 500            | 600           |
| Code blocks     | Cascadia Code  | 500            | 600           |
| Bold (`<b>`)    | Cause      | 500            | 600           |

## Prompts

> A **tip** prompt — run `bundle exec jekyll serve` to preview locally.
{: .prompt-tip }

> An **info** prompt — posts live in the `_posts/` directory and use front matter.
{: .prompt-info }

> A **warning** prompt — double-check `_config.yml` before deploying with `jekyll build`.
{: .prompt-warning }

> A **danger** prompt — never commit secrets like `GITHUB_TOKEN` to the repo.
{: .prompt-danger }

## Keyboard Input

Use <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> to open the command palette.
