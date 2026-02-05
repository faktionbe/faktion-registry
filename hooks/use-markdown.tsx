import React from "react";

export const useMarkdown = (url:string) => {
  const [md, setMd] = React.useState<string>('');
    React.useEffect(() => {
    let cancelled = false;
    const load = async () => {
      const res = await fetch(url, {
        method: 'GET',
        headers: { accept: 'text/markdown' },
      });
      if (!res.ok) {
        throw new Error(`Failed to fetch: ${res.status}`);
      }
      const text = await res.text();
      if (!cancelled) setMd(text);
    };
    load().catch(() => {
      console.error('Failed to load recipe.');
    });
    return () => {
      cancelled = true;
    };
  }, []);
  return md;
};