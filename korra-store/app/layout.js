import { Inter } from 'next/font/google';
import { SITE_URL, BRAND } from '@/lib/config';
import './globals.css';

// Matches the app's GoogleFonts.inter typography. Exposed as --font-inter so
// globals.css can reference it.
const inter = Inter({
  subsets: ['latin'],
  weight: ['400', '500', '600', '700', '800'],
  variable: '--font-inter',
});

export const metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: 'Korra — Reserve today. Complete at your pace.',
    template: '%s · Korra',
  },
  description:
    'Korra lets you reserve items from your favourite stores and pay at your own pace. Discover merchant storefronts and shop flexibly.',
  applicationName: BRAND.name,
  openGraph: {
    type: 'website',
    siteName: BRAND.name,
    url: SITE_URL,
  },
  twitter: { card: 'summary_large_image' },
  robots: { index: true, follow: true },
};

export const viewport = {
  themeColor: BRAND.color,
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={inter.variable}>
      <body>{children}</body>
    </html>
  );
}
