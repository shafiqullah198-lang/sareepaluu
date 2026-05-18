# Saree by Pallu Mobile API

Base URL: `/api/v1/`

Authentication uses Django admin-created users only. There is no signup/register endpoint. Mobile clients use JWT bearer tokens, and browser clients can use the same login endpoint to create a Django session.

## Auth

- `POST /auth/login/` with `username`, `password` returns `access`, `refresh`, `user`, and creates a Django session when called from the web login page.
- `POST /auth/refresh/` with `refresh` returns a new access token.
- `POST /auth/logout/` with optional `refresh` blacklists the refresh token and clears the Django session.
- `GET /auth/me/` returns the current Django user.

## Products

- `GET /products/` list products with variants.
- `POST /products/` create product.
- `GET /products/{id}/` product detail.
- `PATCH /products/{id}/` update product.
- `DELETE /products/{id}/` delete product.
- `GET /products/categories/` list categories and subcategories.
- `GET /products/variants/` list product variants.
- `GET /products/stock/` stock quantity list.
- `GET /products/barcode/{sku}/` lookup by SKU/barcode.

## Customers

- `GET /customers/` list customers.
- `POST /customers/` create customer.
- `GET /customers/{id}/` customer detail with purchase history.
- `PATCH /customers/{id}/` update customer.
- `DELETE /customers/{id}/` delete customer.

## Orders

- `GET /orders/` order history.
- `GET /orders/{id}/` order detail.
- `POST /orders/{id}/payment/` add a payment.
- `PATCH /orders/{id}/status/` update payment status.

## POS

- `GET /pos/cart/` returns categories and products for cart building.
- `POST /pos/checkout/` creates an order, deducts stock, records payment, and returns invoice/order JSON.

Checkout body:

```json
{
  "customer": {"name": "Customer", "phone": "03000000000"},
  "discount": 0,
  "amount_paid": 1500,
  "cart": [
    {"variant_id": 1, "quantity": 1, "price": 1500}
  ]
}
```

## Reports

- `GET /reports/summary/` revenue, orders, customers, profit, low stock.
- `GET /reports/sales/?period=week|month|year` chart-ready sales data.

## Settings

- `GET /settings/company/` company profile.
- `GET /settings/tax/` tax configuration placeholder.

All list endpoints support DRF pagination and search where configured, for example `?search=saree&page=2&page_size=20`. Product/customer writes and POS checkout are staff-protected; read APIs require an authenticated user.
