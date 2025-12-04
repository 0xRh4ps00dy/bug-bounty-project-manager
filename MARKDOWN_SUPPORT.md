# Markdown Support in Checklist Descriptions

## Overview
The Bug Bounty Project Manager now supports **Markdown formatting** for checklist item descriptions. This allows for rich, well-formatted content that improves readability and organization.

## Features

### Text Formatting
- **Bold**: Use `**text**` or `__text__`
- *Italic*: Use `*text*` or `_text_`
- ~~Strikethrough~~: Use `~~text~~`
- `Inline code`: Use backticks

### Headings
Use `#`, `##`, `###` for different heading levels:

```markdown
## Main Section
### Subsection
#### Details
```

### Lists

#### Unordered Lists
```markdown
- Item 1
- Item 2
  - Nested item
  - Another nested
```

#### Ordered Lists
```markdown
1. First step
2. Second step
3. Third step
```

### Code Blocks
Wrap code in triple backticks:

```markdown
\`\`\`
nmap -sV target.com
gobuster dir -u http://target.com -w wordlist.txt
\`\`\`
```

### Blockquotes
Use `>` for quotations:

```markdown
> This is an important note
> Multiple lines supported
```

### Horizontal Rule
Use `---` or `***` to create a separator.

### Links
```markdown
[Link text](https://example.com)
```

## Example Description

```markdown
## Tools & Techniques
- **Wappalyzer**: Browser extension to identify web technologies
- **BuiltWith**: Technology identification service
- **WhatWeb**: Web scanner for CMS identification

## Steps
1. Check HTTP response headers (Server, X-Powered-By, etc.)
2. Look for technology fingerprints in page source
3. Analyze cookies and cache headers
4. Scan for admin panels and common paths

## Common Vulnerabilities
- Outdated software versions
- Unnecessary services running
- Default configurations exposed
```

## Display Features

- **Syntax Highlighting**: Code blocks are displayed with a colored background
- **Automatic Scrolling**: Long descriptions are contained in a scrollable area (max 300px)
- **Color Scheme**: Automatically adapts to light/dark theme
- **Responsive**: Works on all device sizes

## Best Practices

1. **Use clear headings** to organize content into sections
2. **Code examples** should be in code blocks for better visibility
3. **Lists** work better than paragraphs for multiple points
4. **Keep descriptions concise** - remember the context is security testing
5. **Use bold** for important concepts or tool names
6. **Use code formatting** for command examples, file paths, and technical terms

## Theme Support

The markdown renderer automatically detects the current theme and applies appropriate colors:

- **Light Theme**: Dark text on light background, blue accents
- **Dark Theme**: Light text on dark background, adjusted blue accents

## Styling Classes

The rendered markdown is wrapped in the `.markdown-content` class, which provides:

- Appropriate font sizing
- Line height optimization
- Color inheritance from theme variables
- Proper spacing between elements
- Styled code blocks and blockquotes
- Scrollbar customization

## Notes

- HTML is not supported in descriptions (for security reasons)
- Only markdown syntax is processed
- Special characters are HTML-escaped before processing
- The descriptions are stored in the database as plain text with markdown syntax
