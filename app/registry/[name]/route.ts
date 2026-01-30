import { promises as fs } from 'fs';
import { type NextRequest,NextResponse } from 'next/server';
import path from 'path';
import { registryItemSchema } from 'shadcn/registry';

// Use the registry.json file to generate static paths.
export const generateStaticParams = async () => {
  const registryData = await import('@/registry.json');
  const registry = registryData.default;

  return registry.items.map((item) => ({
    name: item.name,
  }));
};

/**
 * Compares the token with the environment variable REGISTRY_AUTH_TOKEN. Environment variable is set in vercel.
 * @param token - The token to validate. (passed in the authorization header or query parameters)
 * @returns 
 */
const isValidToken = async (token: string|null) => token === process.env.REGISTRY_AUTH_TOKEN

// This route shows an example for serving a component using a route handler.
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ name: string }> }
) {
  try {
    const authHeader = request.headers.get("authorization")
    const token = authHeader?.replace("Bearer ", "")

     // Or from query parameters.
  const queryToken = request.nextUrl.searchParams.get("token")
  const isValid = await isValidToken(token ?? queryToken)
  // Check if token is valid.
  if (!isValid) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
  }

    const { name } = await params;
    // Cache the registry import
    const registryData = await import('@/registry.json');
    const registry = registryData.default;

    // Find the component from the registry.
    const component = registry.items.find((item) => item.name === name);

    // If the component is not found, return a 404 error.
    if (!component) {
      return NextResponse.json(
        { error: 'Component not found' },
        { status: 404 }
      );
    }

    // Validate before file operations.
    const registryItem = registryItemSchema.parse(component);

    // If the component has no files, return a 400 error.
    if (!registryItem.files?.length) {
      return NextResponse.json(
        { error: 'Component has no files' },
        { status: 400 }
      );
    }

    // Read all files in parallel.
    const filesWithContent = await Promise.all(
      registryItem.files.map(async (file) => {
        const filePath = path.join(process.cwd(), file.path);
        const content = await fs.readFile(filePath, 'utf8');
        return { ...file, content };
      })
    );

    // Return the component with the files.
    return NextResponse.json({ ...registryItem, files: filesWithContent });
  } catch (error) {
    console.error('Error processing component request:', error);
    return NextResponse.json(
      { error: 'Something went wrong' },
      { status: 500 }
    );
  }
}
