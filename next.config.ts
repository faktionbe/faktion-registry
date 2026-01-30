import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Include registry source files in serverless function bundle
  // Required for Vercel deployment to read files at runtime
  outputFileTracingIncludes: {
    '/api/registry/bearer/[name]': ['./registry/**/*'],
    // Add any other routes that need registry files
    '/api/registry': ['./registry/**/*'],
  },
};

export default nextConfig;
