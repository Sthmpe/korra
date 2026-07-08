import { SITE_URL, productUrl } from '@/lib/config';
import { fetchAllStoreSlugs, fetchAllProductUrls } from '@/lib/api';

// Re-generate the sitemap a few times a day.
export const revalidate = 3600;

export default async function sitemap() {
  const base = [
    { url: `${SITE_URL}/`, changeFrequency: 'weekly', priority: 1 },
  ];

  let slugs = [];
  try {
    slugs = await fetchAllStoreSlugs();
  } catch (e) {
    console.error('sitemap: failed to load slugs', e);
  }

  const stores = slugs.map((slug) => ({
    url: `${SITE_URL}/store/${slug}`,
    changeFrequency: 'daily',
    priority: 0.8,
  }));

  let productUrls = [];
  try {
    productUrls = await fetchAllProductUrls();
  } catch (e) {
    console.error('sitemap: failed to load product urls', e);
  }

  const products = productUrls.map(({ slug, productId }) => ({
    url: productUrl(slug, productId),
    changeFrequency: 'weekly',
    priority: 0.6,
  }));

  return [...base, ...stores, ...products];
}
