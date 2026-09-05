import { NextResponse } from 'next/server';
import { fetchMoreProducts } from '@/lib/api';

// Server-side proxy for lazy pagination so the Supabase key never ships to the
// browser. The client grid calls /api/products?slug=&cursor=.
export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const slug = searchParams.get('slug');
  const cursor = searchParams.get('cursor');
  if (!slug || !cursor) {
    return NextResponse.json({ products: [], nextCursor: null });
  }
  const page = await fetchMoreProducts(slug, cursor);
  return NextResponse.json(page);
}
