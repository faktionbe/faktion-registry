import { type FC } from 'react';

import Component from '@/components/component';
import { useMarkdown } from '@/hooks/use-markdown';

interface MarkdownProps {
  name: string;
  description: string;
  url: string;
}
const Markdown:FC<MarkdownProps> = ({name, description, url}) => {
    const md = useMarkdown(url);
  return (
    <Component
    name={name}
    description={description}
    code={md}>
    <span> Check `code` tab for recipe</span>
  </Component>
  )
}

export default Markdown