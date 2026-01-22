import React, { useEffect } from 'react';
import { type QueryFunction, useInfiniteQuery } from '@tanstack/react-query';
import { useVirtualizer } from '@tanstack/react-virtual';

interface Object {
  id: string;
}

interface CursorPagination<Response extends Object> {
  nextCursor?: string;
  data: Array<Response>;
}

interface UseVirtualizeProps<O extends Object, C extends CursorPagination<O>> {
  queryKey: string;
  queryFn: QueryFunction<C, Array<string>, string>;
}
/**
 * A hook to virtualize a list of items using the infinite query hook and the virtualizer.
 *
 * @example
 * ```tsx
 * const fetchThreads = useThreadsHook();
  const { parentRef, rowVirtualizer, status, hasNextPage, allRows } =
    useVirtualize({
      queryKey: 'threads',
      queryFn: async () =>
        fetchThreads(projectId, {
          take: 10,
          order: 'desc',
        }),
    });

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
              height: `60vh`,
              width: `100%`,
              overflow: 'auto',
            }}>
            <div
              style={{
                height: `${rowVirtualizer.getTotalSize()}px`,
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
                      height: `${virtualRow.size}px`,
                      transform: `translateY(${virtualRow.start}px)`,
                    }}>
                    {isLoaderRow ? (
                      hasNextPage ? (
                        <span className='text-xs text-muted-foreground'>
                          {t('threads.sidebar.loading')}
                        </span>
                      ) : (
                        <span className='text-xs text-muted-foreground'>
                          {t('threads.sidebar.noMoreToLoad')}
                        </span>
                      )
                    ) : (
                      row && <Button variant={'ghost'}>{row.title}</Button>
                    )}
                  </div>
                );
              })}
 * ```
 * @param queryKey - The query key to use for the infinite query.
 * @param queryFn - The query function to use for the infinite query.
 * @returns
 */
export function useVirtualize<O extends Object, C extends CursorPagination<O>>({
  queryKey,
  queryFn,
}: UseVirtualizeProps<O, C>) {
  const { status, data, isFetchingNextPage, fetchNextPage, hasNextPage } =
    useInfiniteQuery({
      queryKey: [queryKey],
      queryFn,
      getNextPageParam: (lastGroup) => lastGroup.nextCursor,
      initialPageParam: '',
    });

  const allRows = data ? data.pages.flatMap((page) => page.data) : [];
  const parentRef = React.useRef<HTMLDivElement>(null);

  const rowVirtualizer = useVirtualizer({
    count: hasNextPage ? allRows.length + 1 : allRows.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 40,
    getItemKey: (index) => allRows[index]?.id ?? index,
    gap: 5,
  });

  const virtualItems = rowVirtualizer.getVirtualItems();

  useEffect(() => {
    const [lastItem] = [...virtualItems].reverse();

    if (!lastItem) {
      return;
    }

    if (
      lastItem.index >= allRows.length - 1 &&
      hasNextPage &&
      !isFetchingNextPage
    ) {
      // fetch next 'page' when the end is reached and there are more pages to load
      // eslint-disable-next-line @typescript-eslint/no-floating-promises
      fetchNextPage();
    }
  }, [
    hasNextPage,
    fetchNextPage,
    allRows.length,
    isFetchingNextPage,
    virtualItems,
  ]);

  return {
    status,
    parentRef,
    rowVirtualizer,
    hasNextPage,
    allRows,
  };
}
