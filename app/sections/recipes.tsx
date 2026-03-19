'use client';


import Markdown from '@/components/markdown';

const Recipes = () => (
    <>
    <Markdown name="microsoft-sso" description="A Microsoft SSO recipe" url="/api/recipes/microsoft-sso" />
    <Markdown name="prompthandler" description="Python prompthandler package" url="/api/recipes/prompthandler" />
    <Markdown name="aws" description="An AWS Terraform infrastructure recipe" url="/api/recipes/aws" />
    </>
  );

export default Recipes;
