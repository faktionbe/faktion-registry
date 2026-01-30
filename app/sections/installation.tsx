import React from 'react';

import { CodeBlockContent } from '@/components/blocks/code-block';

const Installation = () => (
  <>
    <a href='#installation'>Installation</a>
    <CodeBlockContent language='markdown'>
      {`\`\`\`md
# Faktion Registry

The registry contains components, reusable blocks and recipes. Stuff that does not belong in faktion-kickstarter will end up here.

We protect our registry with a token.
You can get the token from 1Password.

## Installation

Add a \`components.json\` file to your app with the following content:

\`\`\`json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "registries": {
    "@faktion": {
      "url": "https://registry.faktion.com/api/registry/bearer/{name}",
      "headers": {
        "Authorization": "Bearer TOKEN_FROM_1PASSWORD"
      }
    }
  }
}
\`\`\`

\`\`\`sh
pnpm dlx shadcn@latest add @faktion/{name}
\`\`\`
`}
    </CodeBlockContent>
  </>
);
export default Installation;
