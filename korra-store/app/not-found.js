import { SITE_URL, CUSTOMER_WEBAPP } from '@/lib/config';

export const metadata = { robots: { index: false } };

export default function NotFound() {
  return (
    <>
      <header className="topbar">
        <div className="container topbar-inner">
          <a className="logo" href={SITE_URL}>
            Korra<span>.</span>
          </a>
          <a className="btn btn-soft" href={CUSTOMER_WEBAPP}>
            Open app
          </a>
        </div>
      </header>
      <div className="notice">
        <div className="notice-icon" style={{ background: '#fff2eb', color: '#a54600' }}>
          🔍
        </div>
        <h1>Store not found</h1>
        <p>
          We couldn&apos;t find this storefront. The link may be broken or the
          store may have changed its address.
        </p>
        <p style={{ marginTop: 20 }}>
          <a className="btn btn-brand" href={SITE_URL}>
            Back to Korra
          </a>
        </p>
      </div>
    </>
  );
}
