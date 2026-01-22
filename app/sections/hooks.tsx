import React from 'react';

import Component from '@/components/component';

const Hooks = () => (
  <>
    <Component
      name='use-composition'
      description='A hook to extract children of a specific type from a composition'
      code={`
       const [children, childComponents] = useComposition(children, 'ChildComponent');
       return (
        <div>
          {children}
          {childComponents.map((child) => (
            <div key={child.key}>{child}</div>
          ))}
        </div>
       );
        `}>
      <span> Check `code` tab for usage</span>
    </Component>
    <Component
      name='use-file-download'
      description='A hook to download a file'
      code={`
       const { downloadFile } = useFileDownload({
        mutationKey: 'download-file',
        path: 'https://example.com/file.pdf',
       });
       downloadFile();
        `}>
      <span> Check `code` tab for usage</span>
    </Component>
    <Component
      name='use-download'
      description='A hook to download from a url'
      code={`
       const { download } = useDownload();
       download({ url: 'https://example.com/file.pdf', file: 'file.pdf' });
        `}>
      <span> Check `code` tab for usage</span>
    </Component>
    <Component
      name='use-virtualize'
      description='A hook to virtualize a list of items'
      code={`
  const fetchThreads = useThreadsHook();
  const { parentRef, rowVirtualizer, status, hasNextPage, allRows } =
    useVirtualize({
      queryKey: 'threads',
      queryFn: async () =>
        fetchThreads(projectId, {
          take: 10,
          order: 'desc',
        }),
    });

  return (
    <div className='flex h-full w-64 flex-col border-r bg-muted/30'>
      <div className='flex items-center justify-between border-b px-4 py-3'>
        <h2 className='text-sm font-semibold'>Threads</h2>
        <Button
          variant='ghost'
          size='icon'
          className='size-7'>
          <Plus className='size-4' />
          <span className='sr-only'>Add new</span>
        </Button>
      </div>

      <div className='px-3 py-2'>
        <Input
          placeholder='Search'
          className='h-8 bg-background'
        />
      </div>

      <div className='px-3 py-2'>
        {status === 'pending' ? (
          <div className='flex flex-col items-center justify-center gap-2'>
            <Spinner />
            <span className='text-xs'>Loading</span>
          </div>
        ) : status === 'error' ? (
          <span className='text-destructive text-xs'>
            Error loading
          </span>
        ) : (
          <div
            ref={parentRef}
            className='max-w-full'
            style={{
              height: '60vh',
              width: '100%',
              overflow: 'auto',
            }}>
            <div
              style={{
                height: rowVirtualizer.getTotalSize() + 'px',
                width: '100%',
                position: 'relative',
              }}>
              {rowVirtualizer.getVirtualItems().map((virtualRow) => {
                const isLoaderRow = virtualRow.index > allRows.length - 1;
                const row = allRows[virtualRow.index];

                return (
                  <div
                    key={virtualRow.index}
                    style={{
                      position: 'absolute',
                      top: 0,
                      left: 0,
                      width: '100%',
                      height: virtualRow.size + 'px',
                      transform: 'translateY(' + virtualRow.start + 'px)',
                    }}>
                    {isLoaderRow ? (
                      hasNextPage ? (
                        <span className='text-xs text-muted-foreground'>
                          Loading
                        </span>
                      ) : (
                        <span className='text-xs text-muted-foreground'>
                          No more to load
                        </span>
                      )
                    ) : (
                      row && <Button variant={'ghost'}>{row.title}</Button>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  );`}>
      <span> Check `code` tab for usage</span>
    </Component>
  </>
);

export default Hooks;
