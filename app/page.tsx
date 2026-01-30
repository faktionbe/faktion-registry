'use client';

import Chat from '@/app/sections/chat';
import Default from '@/app/sections/default';
import Forms from '@/app/sections/forms';
import Hooks from '@/app/sections/hooks';
import Installation from '@/app/sections/installation';
import Recipes from '@/app/sections/recipes';
import Table from '@/app/sections/table';

const Home = () => (
  <div className='max-w-3xl mx-auto flex flex-col min-h-svh px-4 py-8 gap-8'>
    <header className='flex flex-col gap-1'>
      <h1 className='text-3xl font-bold tracking-tight'>Faktion Registry</h1>
      <p className='text-muted-foreground'>A custom registry for Faktion.</p>
    </header>
    <main className='flex flex-col flex-1 gap-8'>
      <Installation />
      <Default />
      <Forms />
      <Chat />
      <Table />
      <Hooks />
      <Recipes />
    </main>
  </div>
);

export default Home;
