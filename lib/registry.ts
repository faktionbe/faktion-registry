import { promises as fs } from 'fs';
import path from 'path';
import { registryItemSchema } from 'shadcn/schema';

export async function getItemFromRegistry(name: string) {
  const registryData = await import('@/registry.json');
  const registry = registryData.default;

  if (name === 'registry') {
    return registry;
  }

  const component = registry.items.find((item) => item.name === name);

  if (!component) {
    return null;
  }

  const parsed = registryItemSchema.parse(component);

  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  if (!parsed) {
    return null;
  }

  if (!parsed.files?.length) {
    return null;
  }

  const filesWithContent = await Promise.all(
    parsed.files.map(async (file) => {
      const filePath = path.join(process.cwd(), file.path);
      const content = await fs.readFile(filePath, 'utf8');
      return { ...file, content };
    })
  );

  return { ...parsed, files: filesWithContent };
}
