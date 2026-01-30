import { useMemo } from 'react';

import registry from '@/registry.json';

type RegistryItem = (typeof registry.items)[number];

const GETTING_STARTED_CATEGORY = 'Getting started';
const COMPONENTS_CATEGORY = 'components';

export function useCategories() {
  const categories = useMemo(() => {
    const set = new Set<string>();
    set.add(GETTING_STARTED_CATEGORY);
    set.add(COMPONENTS_CATEGORY);
    registry.items.forEach((item) => {
      item.categories?.forEach((category) => {
        set.add(category);
      });
    });
    return Array.from(set);
  }, []);

  const itemsPerCategory = useMemo(() => {
    const map = new Map<string, Array<RegistryItem>>();

    categories.forEach((category) => {
      if (category === COMPONENTS_CATEGORY) {
        map.set(
          category,
          registry.items.filter(
            (item) => !item.categories || item.categories.length === 0
          )
        );
      } else if (category === GETTING_STARTED_CATEGORY) {
        map.set(GETTING_STARTED_CATEGORY, [
          {
            name: 'installation',
            title: 'installation',
          } as RegistryItem,
        ]);
      } else {
        map.set(
          category,
          registry.items.filter((item) => item.categories?.includes(category))
        );
      }
    });

    return map;
  }, [categories]);

  return { categories, itemsPerCategory };
}
