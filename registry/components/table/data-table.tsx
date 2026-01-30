import { type ComponentType,Fragment } from 'react';
import {
  flexRender,
  type Row,
  Table as TanstackTable,
} from '@tanstack/react-table';

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { cn } from '@/lib/utils';
import { Pagination } from '@/registry/components/table/pagination';

interface DataTableProps<TData> {
  table: TanstackTable<TData>;
  empty?: string;
  isNested?: boolean;
  expansion?: ComponentType<{ row: Row<TData> }>;
  onRowClick?: (row: Row<TData>) => void;
}

export const DataTable = <TData,>({
  table,
  empty,
  isNested = false,
  // eslint-disable-next-line @typescript-eslint/naming-convention
  expansion: Expansion,
  onRowClick,
}: DataTableProps<TData>) => {
  const columns = table.getAllColumns();

  return (
    <div className='flex flex-col gap-4'>
      <div
        className={cn({
          'rounded-md border': !isNested,
        })}>
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup,i) => (
              <TableRow key={headerGroup.id + i}>
                {headerGroup.headers.map((header) => (
                  <TableHead key={header.id}>
                    {header.isPlaceholder
                      ? null
                      : flexRender(
                          header.column.columnDef.header,
                          header.getContext()
                        )}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows.length ? (
              table.getRowModel().rows.map((row, i) => (
                <Fragment key={row.id + i}>
                  <TableRow
                    data-state={row.getIsSelected() && 'selected'}
                    data-clickable={typeof onRowClick === 'function'}
                    onClick={() => onRowClick?.(row)}>
                    {row.getVisibleCells().map((cell) => (
                      <TableCell key={cell.id}>
                        {flexRender(
                          cell.column.columnDef.cell,
                          cell.getContext()
                        )}
                      </TableCell>
                    ))}
                  </TableRow>
                  {row.getIsExpanded() && Expansion && (
                    <TableRow>
                      <td colSpan={columns.length}>
                        <Expansion row={row} />
                      </td>
                    </TableRow>
                  )}
                </Fragment>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className='h-24 text-center'>
                  {empty ?? 'No results'}
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      {!isNested && <Pagination table={table} />}
    </div>
  );
};
