import { NextResponse } from 'next/server';
import fs from 'node:fs/promises';
import path from 'node:path';

export async function GET() {
  try {
    const markdownPath = path.join(
      process.cwd(),
      'registry',
      'recipes',
      'infrastructure',
      'aws',
      'AWS.md'
    );
    const md = await fs.readFile(markdownPath, 'utf8');
    return new Response(md, {
      headers: {
        'content-type': 'text/markdown; charset=utf-8',
        'cache-control': 's-maxage=300, stale-while-revalidate=86400',
      },
    });
  } catch (error) {
    console.error('Failed to load AWS Infrastructure recipe.', error);
    return NextResponse.json(
      { error: 'Failed to load AWS Infrastructure recipe.' },
      { status: 500 }
    );
  }
}
